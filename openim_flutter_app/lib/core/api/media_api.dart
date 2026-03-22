/// Media upload API — 通过 im-server 对象存储（/object/*）上传文件
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class MediaApi {
  /// 上传文件到 im-server 对象存储，返回可公开访问的 URL；失败返回 null。
  ///
  /// 流程：
  ///   1. POST /object/initiate_form_data → 获取上传凭证
  ///   2. 按凭证上传文件到存储后端（S3/MinIO）
  ///   3. POST /object/complete_form_data → 确认上传，获取最终 URL
  static Future<String?> uploadFile({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      // Step 1: 获取上传凭证（name 须以 userID/ 为前缀，否则 IM 服务器返回 NoPermissionError）
      final objectName =
          '${ApiConfig.userID}/${DateTime.now().millisecondsSinceEpoch}_$filename';
      debugPrint(
          '[MediaApi] Step1: initiate_form_data objectName=$objectName size=${bytes.length}');
      final initResp = await ImApi.post('/object/initiate_form_data', {
        'name': objectName,
        'size': bytes.length,
        'contentType': _guessMimeType(filename),
      });
      debugPrint(
          '[MediaApi] Step1 response: errCode=${initResp['errCode']}, data keys=${(initResp['data'] as Map?)?.keys}');
      if ((initResp['errCode'] as int?) != 0) {
        debugPrint(
            '[MediaApi] initiate_form_data 失败: ${initResp['errCode']} ${initResp['errMsg']}');
        return null;
      }
      final data = initResp['data'] as Map<String, dynamic>? ?? {};
      final uploadId = data['id'] as String? ?? '';
      final uploadUrl = data['url'] as String? ?? '';
      final fileField = data['file'] as String?;
      final formData = data['formData'] as Map<String, dynamic>?;
      final headerMap = data['header'] as Map<String, dynamic>?;
      debugPrint(
          '[MediaApi] uploadUrl=$uploadUrl, id=$uploadId, fileField=$fileField, hasFormData=${formData != null}');

      if (uploadId.isEmpty || uploadUrl.isEmpty) {
        debugPrint(
            '[MediaApi] initiate_form_data 返回数据不完整: id=$uploadId url=$uploadUrl');
        return null;
      }

      // Step 2: 上传文件到存储后端
      debugPrint('[MediaApi] Step2: uploading to $uploadUrl');
      final uploadSuccess = await _uploadToStorage(uploadUrl, bytes, filename,
          fileField, formData, headerMap, data['successCodes']);
      debugPrint('[MediaApi] Step2 result: $uploadSuccess');
      if (!uploadSuccess) {
        debugPrint('[MediaApi] 文件上传到存储后端失败 url=$uploadUrl');
        return null;
      }

      // Step 3: 确认上传，获取最终 URL
      final completeResp = await ImApi.post('/object/complete_form_data', {
        'id': uploadId,
      });
      if ((completeResp['errCode'] as int?) != 0) {
        debugPrint('complete_form_data 失败: ${completeResp['errMsg']}');
        return null;
      }
      return completeResp['data']?['url'] as String?;
    } catch (e) {
      debugPrint('文件上传异常: $e');
      return null;
    }
  }

  /// 根据凭证上传文件到存储后端
  static Future<bool> _uploadToStorage(
    String url,
    List<int> bytes,
    String filename,
    String? fileField,
    Map<String, dynamic>? formData,
    Map<String, dynamic>? headerMap,
    dynamic successCodes,
  ) async {
    final client = http.Client();
    try {
      final validCodes = <int>{};
      if (successCodes is List) {
        for (final c in successCodes) {
          if (c is int) validCodes.add(c);
          if (c is num) validCodes.add(c.toInt());
        }
      }
      if (validCodes.isEmpty) {
        validCodes.addAll([200, 201, 204]);
      }

      // 构建请求头
      final headers = <String, String>{};
      if (headerMap != null) {
        for (final entry in headerMap.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            headers[entry.key] = (entry.value as List).first.toString();
          } else if (entry.value is String) {
            headers[entry.key] = entry.value as String;
          }
        }
      }

      if (formData != null && formData.isNotEmpty) {
        // Multipart form upload (S3 presigned POST)
        debugPrint('[MediaApi] Multipart POST to $url fields=${formData.keys}');
        final req = http.MultipartRequest('POST', Uri.parse(url))
          ..headers.addAll(headers);
        for (final entry in formData.entries) {
          req.fields[entry.key] = entry.value.toString();
        }
        req.files.add(http.MultipartFile.fromBytes(
          fileField ?? 'file',
          bytes,
          filename: filename,
        ));
        final resp = await req.send().timeout(const Duration(seconds: 120));
        debugPrint(
            '[MediaApi] Multipart response: ${resp.statusCode} validCodes=$validCodes');
        if (!validCodes.contains(resp.statusCode)) {
          final body = await resp.stream.bytesToString();
          debugPrint('[MediaApi] Upload error body: $body');
        }
        return validCodes.contains(resp.statusCode);
      } else {
        // Direct PUT upload
        debugPrint('[MediaApi] PUT to $url');
        headers['Content-Type'] = _guessMimeType(filename);
        final resp = await client
            .put(Uri.parse(url), headers: headers, body: bytes)
            .timeout(const Duration(seconds: 120));
        debugPrint(
            '[MediaApi] PUT response: ${resp.statusCode} validCodes=$validCodes');
        if (!validCodes.contains(resp.statusCode)) {
          debugPrint('[MediaApi] PUT error body: ${resp.body}');
        }
        return validCodes.contains(resp.statusCode);
      }
    } finally {
      client.close();
    }
  }

  static String _guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const mimeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip': 'application/zip',
    };
    return mimeMap[ext] ?? 'application/octet-stream';
  }
}
