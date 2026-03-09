/// Auth API — login / register / get token
library;

import 'api_client.dart';

class AuthApi {
  /// 用户登录 (chat-api)
  static Future<Map<String, dynamic>> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    int platform = 1,
  }) async {
    return ChatApi.post('/account/login', {
      'areaCode': areaCode,
      'phoneNumber': phoneNumber,
      'password': password,
      'platform': platform,
    });
  }

  /// 用户注册 (chat-api)
  static Future<Map<String, dynamic>> register({
    required String areaCode,
    required String phoneNumber,
    required String password,
    required String nickname,
    String? invitationCode,
  }) async {
    return ChatApi.post('/account/register', {
      'user': {
        'areaCode': areaCode,
        'phoneNumber': phoneNumber,
        'password': password,
        'nickname': nickname,
      },
      if (invitationCode != null) 'invitationCode': invitationCode,
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
}
