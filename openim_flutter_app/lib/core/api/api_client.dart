/// OpenIM API client configuration and HTTP wrapper.
/// 兼容 OpenIM v3.8.x 架构：chat(10008) + open-im-server(10002/10001)。
/// 二次开发规范：仅修改配置与调用层，不改 SDK 核心。
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// 后端服务主机。H5/真机访问时改为本机局域网 IP（如 192.168.1.100），
  /// 或通过编译参数覆盖：flutter run -d chrome --dart-define=API_HOST=192.168.1.100
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.0.136',
  );

  /// im-server API (port 10002)
  static String get imApiBase => 'http://$apiHost:10002';

  /// chat-api 用户登录/注册 (port 10008)
  static String get chatApiBase => 'http://$apiHost:10008';

  /// admin-api (port 10009)
  static String get adminApiBase => 'http://$apiHost:10009';

  /// WebSocket gateway for message push
  static String get wsUrl => 'ws://$apiHost:10001';

  static String imToken = '';
  static String chatToken = '';
  static String userID = '';

  /// Whether running on desktop (Windows/macOS/Linux)
  static bool isDesktop = false;

  /// Whether running on web
  static bool isWeb = false;
}

class ImApi {
  static final _client = http.Client();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (ApiConfig.imToken.isNotEmpty) 'token': ApiConfig.imToken,
        'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  /// POST to im-server
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final resp = await _client.post(
      Uri.parse('${ApiConfig.imApiBase}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}

class ChatApi {
  static final _client = http.Client();

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (ApiConfig.chatToken.isNotEmpty) 'token': ApiConfig.chatToken,
        'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  /// POST to chat-api
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final resp = await _client.post(
      Uri.parse('${ApiConfig.chatApiBase}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
