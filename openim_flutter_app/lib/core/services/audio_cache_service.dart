import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 语音文件本地缓存服务。
///
/// 首次播放时将远端 URL 下载到应用临时目录；
/// 之后相同 URL 直接读取本地文件，避免重复流量。
///
/// 缓存键：URL 的 MD5-like 哈希（用 hashCode + 文件名后缀）。
class AudioCacheService {
  AudioCacheService._();
  static final instance = AudioCacheService._();

  /// 内存索引 url → 本地路径
  final Map<String, String> _memCache = {};

  /// 返回本地可播放路径。
  /// - 若已缓存直接返回。
  /// - 若未缓存则下载并写入磁盘。
  /// - Web 平台无本地 FS，直接返回 null（由调用方回退到 UrlSource）。
  Future<String?> resolve(String url) async {
    if (kIsWeb) return null;
    if (url.isEmpty) return null;

    if (_memCache.containsKey(url)) {
      final cached = _memCache[url]!;
      if (await File(cached).exists()) return cached;
      _memCache.remove(url); // 文件已被系统清理
    }

    try {
      final dir = await getTemporaryDirectory();
      final ext = _extFromUrl(url);
      final filename = 'voice_${url.hashCode.abs()}$ext';
      final file = File('${dir.path}/$filename');

      if (await file.exists()) {
        _memCache[url] = file.path;
        return file.path;
      }

      // 下载
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _memCache[url] = file.path;
        return file.path;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AudioCacheService: 下载失败 $e');
    }
    return null;
  }

  /// 清除所有已缓存文件（可在应用清理数据时调用）
  Future<void> clearAll() async {
    if (kIsWeb) return;
    try {
      final dir = await getTemporaryDirectory();
      final cacheFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('voice_'));
      for (final f in cacheFiles) {
        await f.delete();
      }
      _memCache.clear();
    } catch (e) {
      debugPrint('清除语音缓存失败: $e');
    }
  }

  String _extFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '.m4a';
    final path = uri.path;
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && (path.length - dot) <= 5) return path.substring(dot);
    return '.m4a';
  }
}
