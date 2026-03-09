/// OpenIM API client configuration and HTTP wrapper.
/// 兼容 OpenIM v3.8.x 架构：chat(10008) + open-im-server(10002/10001)。
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// 后端服务主机。H5/真机访问时改为本机局域网 IP（如 192.168.1.100），
  /// 或通过编译参数覆盖：flutter run --dart-define=API_HOST=192.168.1.100
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.0.136',
  );

  static String get imApiBase => 'http://$apiHost:10002';
  static String get chatApiBase => 'http://$apiHost:10008';
  static String get adminApiBase => 'http://$apiHost:10009';
  static String get wsUrl => 'ws://$apiHost:10001';

  static String imToken = '';
  static String chatToken = '';
  static String userID = '';

  static bool isDesktop = false;
  static bool isWeb = false;

  /// 网络超时：10秒（加载态从请求发出即显示，禁止静默等待）
  static const Duration requestTimeout = Duration(seconds: 10);
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
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.imApiBase}$path'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
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

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.chatApiBase}$path'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
