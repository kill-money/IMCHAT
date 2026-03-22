/// Status API — 在线状态查询 + 隐私设置
/// 路由至 chat-api (10008)，与钱包、IP 等自定义扩展保持一致。
library;

import 'api_client.dart';
import '../models/user_status.dart';

class StatusApi {
  /// 查询单用户在线状态
  /// GET /user/status (用 POST 包装，OpenIM 约定)
  static Future<UserStatus?> getUserStatus(String userID) async {
    try {
      final res = await ChatApi.post('/user/status', {'userID': userID});
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) return null;
      final data = res['data'];
      if (data == null) return null;
      return UserStatus.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 批量查询在线状态（MGET，≤100 个 userID）
  /// POST /user/status/batch
  static Future<List<UserStatus>> getBatchStatus(List<String> userIDs) async {
    if (userIDs.isEmpty) return [];
    try {
      final res = await ChatApi.post(
        '/user/status/batch',
        {'userIDs': userIDs},
      );
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) return [];
      final list = res['data'];
      if (list == null || list is! List) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(UserStatus.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 读取当前用户的 last_seen 隐私设置
  /// POST /user/privacy/get
  static Future<LastSeenPrivacy> getMyPrivacy() async {
    try {
      final res = await ChatApi.post('/user/privacy/get', {});
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) return LastSeenPrivacy.everyone;
      final val = res['data']?['lastSeenPrivacy']?.toString();
      return LastSeenPrivacyX.fromApi(val);
    } catch (_) {
      return LastSeenPrivacy.everyone;
    }
  }

  /// 更新当前用户的 last_seen 隐私设置
  /// POST /user/privacy/set
  static Future<bool> setMyPrivacy(LastSeenPrivacy privacy) async {
    try {
      final res = await ChatApi.post(
        '/user/privacy/set',
        {'lastSeenPrivacy': privacy.apiValue},
      );
      return (res['errCode'] ?? 0) as int == 0;
    } catch (_) {
      return false;
    }
  }

  // ── Presence API ────────────────────────────────────────────────────────────

  /// POST /presence/heartbeat — 心跳续命（刷新在线 TTL）
  static Future<bool> heartbeat() async {
    try {
      final res = await ChatApi.post('/presence/heartbeat', {});
      return (res['errCode'] ?? 0) as int == 0;
    } catch (_) {
      return false;
    }
  }

  /// POST /presence/offline — 显式离线
  static Future<bool> goOffline() async {
    try {
      final res = await ChatApi.post('/presence/offline', {});
      return (res['errCode'] ?? 0) as int == 0;
    } catch (_) {
      return false;
    }
  }
}
