/// Auth API — login / register / get token
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'api_client.dart';

/// SHA-256 hex digest of [input].
/// 密码在传输前统一哈希，服务端以相同哈希值存储/比对，
/// 原始密码不出设备，降低明文泄露风险。
String _sha256Hex(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}

class AuthApi {
  /// 用户登录 (chat-api)
  static Future<Map<String, dynamic>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    int platform = 1,
    String deviceID = '',
  }) async {
    return ChatApi.post('/account/login', {
      'areaCode': areaCode,
      'phoneNumber': phoneNumber,
      'password': _sha256Hex(password),
      'platform': platform,
      'deviceID': deviceID,
    });
  }

  /// 白名单预检（admin-api 公开端点）
  /// 在发送密码前先验证账号是否在白名单内，避免暴露密码给后端再拦截
  /// errCode 20015 = 不在白名单，20016 = 白名单已停用
  static Future<Map<String, dynamic>> checkWhitelist({
    required String identifier, // 带区号手机号或邮箱
  }) async {
    return AdminApi.post('/whitelist/check', {
      'identifier': identifier,
    });
  }

  /// 用户注册 (chat-api)
  static Future<Map<String, dynamic>> register({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required String nickname,
    String? invitationCode,
    String? downloadReferrer, // 推荐人 ID（来自下载链接 ?ref=）
    int platform = 1,
    String deviceID = '',
  }) async {
    return ChatApi.post('/account/register', {
      'platform': platform,
      'deviceID': deviceID,
      'autoLogin': false,
      'verifyCode': '666666',
      'user': {
        'areaCode': areaCode,
        'phoneNumber': phoneNumber,
        'password': _sha256Hex(password),
        'nickname': nickname,
      },
      if (invitationCode != null && invitationCode.isNotEmpty)
        'invitationCode': invitationCode,
      if (downloadReferrer != null && downloadReferrer.isNotEmpty)
        'downloadReferrer': downloadReferrer,
    });
  }

  /// 用户修改自己的密码（需要 chat token）
  /// 当前密码和新密码均在客户端做 SHA-256，与登录/注册保持一致
  static Future<Map<String, dynamic>> changePassword({
    required String userID,
    required String currentPassword,
    required String newPassword,
  }) async {
    return ChatApi.post('/account/password/change', {
      'userID': userID,
      'currentPassword': _sha256Hex(currentPassword),
      'newPassword': _sha256Hex(newPassword),
    });
  }

  /// 获取 im-server token
  static Future<Map<String, dynamic>> getUserToken({
    required String userID,
    int platformID = 1,
  }) async {
    return ImApi.post('/auth/get_user_token', {
      'userID': userID,
      'platformID': platformID,
    });
  }

  /// 发送验证码 (chat-api POST /account/code/send)
  /// [usedFor] 1=注册  2=找回密码
  /// 手机端传 [areaCode]+[phoneNumber]，邮箱端传 [email]
  static Future<Map<String, dynamic>> sendVerifyCode({
    required int usedFor,
    required String areaCode,
    required String phoneNumber,
    String? email,
    String? invitationCode,
    int platform = 1,
    String deviceID = '',
  }) async {
    return ChatApi.post('/account/code/send', {
      'usedFor': usedFor,
      'areaCode': areaCode,
      'phoneNumber': phoneNumber,
      if (email != null && email.isNotEmpty) 'email': email,
      if (invitationCode != null && invitationCode.isNotEmpty)
        'invitationCode': invitationCode,
      'platform': platform,
      'deviceID': deviceID,
    });
  }

  /// 校验验证码 (chat-api POST /account/code/verify)
  static Future<Map<String, dynamic>> verifyCode({
    required String areaCode,
    required String phoneNumber,
    required String verifyCode,
    String? email,
  }) async {
    return ChatApi.post('/account/code/verify', {
      'areaCode': areaCode,
      'phoneNumber': phoneNumber,
      'verifyCode': verifyCode,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  /// 通过验证码重置密码 (chat-api POST /account/password/reset)
  /// 新密码在客户端做 SHA-256，与登录/注册保持一致
  static Future<Map<String, dynamic>> resetPassword({
    required String areaCode,
    required String phoneNumber,
    required String verifyCode,
    required String newPassword,
    String? email,
  }) async {
    return ChatApi.post('/account/password/reset', {
      'areaCode': areaCode,
      'phoneNumber': phoneNumber,
      'verifyCode': verifyCode,
      'password': _sha256Hex(newPassword),
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }
}
