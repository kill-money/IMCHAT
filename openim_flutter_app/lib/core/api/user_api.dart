/// 用户相关 API（查询 IP、用户信息等）
library;

import 'api_client.dart';

class UserApi {
  /// 查询指定用户最后登录 IP（仅用户端管理员或超级管理员可调）
  /// POST /user/ip_info → { errCode, data: { userID, lastIP, lastIPTime } }
  static Future<Map<String, dynamic>> getUserIPInfo({
    required String targetUserID,
  }) async {
    return ChatApi.post('/user/ip_info', {'targetUserID': targetUserID});
  }
}
