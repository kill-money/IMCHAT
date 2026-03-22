/// OpenIM API client configuration and HTTP wrapper.
/// 兼容 OpenIM v3.8.x 架构：chat(10008) + open-im-server(10002/10001)。
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../network/network_interceptor.dart';

class ApiConfig {
  /// 后端服务主机。通过编译参数覆盖：flutter run --dart-define=API_HOST=`<ip>`
  ///
  /// 不同环境说明：
  ///   Android 模拟器  → --dart-define=API_HOST=10.0.2.2
  ///   iOS 模拟器      → --dart-define=API_HOST=127.0.0.1
  ///   真机 / 局域网   → --dart-define=API_HOST=<服务器内网 IP>
  ///   生产部署         → --dart-define=API_HOST=<公网 IP 或域名>
  ///
  /// 默认值 127.0.0.1 适用于本机开发调试；真机/局域网需通过 --dart-define 覆盖。
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );

  /// 启动时打印实际使用的 API 地址（调试用）
  static void debugPrintHost() {
    debugPrint(
        '[API_HOST] chatApiBase=$chatApiBase, imApiBase=$imApiBase, wsUrl=$wsUrl');
  }

  static String get imApiBase => 'http://$apiHost:10002';
  static String get chatApiBase => 'http://$apiHost:10008';
  static String get adminApiBase => 'http://$apiHost:10009';
  static String get wsUrl => 'ws://$apiHost:10001';

  /// Presence WebSocket Gateway（Phase 2）
  /// 连接时需携带 chat-token：ws://host:10008/ws/presence?token={chatToken}
  static String get presenceWsUrl => 'ws://$apiHost:10008/ws/presence';

  static String imToken = '';
  static String chatToken = '';
  static String userID = '';

  static bool isDesktop = false;
  static bool isWeb = false;

  /// 推荐系统 — 下载链接中的 ?ref= 参数，在 main.dart 启动时解析并保存
  static String downloadReferrer = '';

  /// 网络超时：10秒（加载态从请求发出即显示，禁止静默等待）
  static const Duration requestTimeout = Duration(seconds: 10);

  // ─── Token 过期全局拦截 ──────────────────────────────────────────────────

  /// 在 main.dart 中将此 key 绑定到 MaterialApp.navigatorKey，
  /// 使 API 层无需持有 BuildContext 即可主动导航。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// errCode 1501 = Token 过期, 1503 = Token 格式错误, 1506 = Token 被踢下线,
  /// 1507 = Token 不存在。清理本地凭证并跳转到登录页。
  static bool isTokenError(int? code) =>
      code == 1501 || code == 1503 || code == 1506 || code == 1507;

  static void handleTokenExpired() {
    imToken = '';
    chatToken = '';
    userID = '';
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class ImApi {
  static final _client = http.Client();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (ApiConfig.imToken.isNotEmpty) 'token': ApiConfig.imToken,
        'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    debugPrint('[API_REQUEST] IM $path body=${body.keys}');
    return NetworkInterceptor.execute(() async {
      try {
        final resp = await _client
            .post(
              Uri.parse('${ApiConfig.imApiBase}$path'),
              headers: _headers(),
              body: jsonEncode(body),
            )
            .timeout(ApiConfig.requestTimeout);
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        debugPrint('[API_RESPONSE] IM $path errCode=${json['errCode']}');
        if (ApiConfig.isTokenError(json['errCode'] as int?)) {
          ApiConfig.handleTokenExpired();
        }
        return json;
      } on FormatException {
        return {'errCode': -1, 'errMsg': '服务不可用'};
      }
    });
  }
}

class ChatApi {
  static final _client = http.Client();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (ApiConfig.chatToken.isNotEmpty) 'token': ApiConfig.chatToken,
        'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final bodyJson = jsonEncode(body);
    debugPrint('[API_REQUEST] Chat $path body=${body.keys}');
    return NetworkInterceptor.execute(() async {
      try {
        final url = '${ApiConfig.chatApiBase}$path';
        final resp = await _client
            .post(
              Uri.parse(url),
              headers: _headers(),
              body: bodyJson,
            )
            .timeout(ApiConfig.requestTimeout);
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        debugPrint('[API_RESPONSE] Chat $path errCode=${json['errCode']}');
        if (ApiConfig.isTokenError(json['errCode'] as int?)) {
          ApiConfig.handleTokenExpired();
        }
        return json;
      } on FormatException catch (e) {
        debugPrint('[API_ERROR] Chat $path FormatException: $e');
        return {'errCode': -1, 'errMsg': '服务不可用'};
      }
    });
  }
}

/// AdminApi 对应 admin-api（10009 端口）— 部分接口无需 token（如白名单预检）
class AdminApi {
  static final _client = http.Client();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    debugPrint('[API_REQUEST] Admin $path body=${body.keys}');
    return NetworkInterceptor.execute(() async {
      try {
        final resp = await _client
            .post(
              Uri.parse('${ApiConfig.adminApiBase}$path'),
              headers: _headers(),
              body: jsonEncode(body),
            )
            .timeout(ApiConfig.requestTimeout);
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        debugPrint('[API_RESPONSE] Admin $path errCode=${json['errCode']}');
        return json;
      } on FormatException {
        return {'errCode': -1, 'errMsg': '服务不可用'};
      }
    });
  }
}
