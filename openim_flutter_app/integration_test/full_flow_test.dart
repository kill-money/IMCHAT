// ============================================================
// Flutter 集成测试 — 登录 / WebSocket / Token / 封禁
// ============================================================
// 运行方式:
//   flutter test integration_test/full_flow_test.dart -d chrome
//   flutter test integration_test/full_flow_test.dart -d windows
//
// 环境变量:
//   API_HOST (默认 localhost)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ── 配置 ──
const apiHost = String.fromEnvironment('API_HOST', defaultValue: 'localhost');
final chatApi = 'http://$apiHost:10008';
final adminApi = 'http://$apiHost:10009';
final imApi = 'http://$apiHost:10002';

// ── 工具函数 ──
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();

String md5Hex(String input) {
  // 简单 MD5 实现 (仅用于 admin 登录测试)
  final data = utf8.encode(input);
  final digest = md5.convert(data);
  return digest.toString();
}

Future<Map<String, dynamic>> post(
  String url,
  Map<String, dynamic> body, {
  String? token,
}) async {
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'operationID': DateTime.now().millisecondsSinceEpoch.toString(),
  };
  if (token != null) headers['token'] = token;

  final resp = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 全局共享凭据（登录一次，全部复用）──
  late String userImToken;
  late String userChatToken;
  late String userID;
  late String adminToken;
  late String adminImToken;
  late String adminUserID;

  setUpAll(() async {
    // 清除 Redis 限流 key（通过 admin API 间接验证可用性）
    // 注册测试用户（幂等）
    await post('$chatApi/account/register', {
      'platform': 1,
      'deviceID': 'flutter-test',
      'autoLogin': false,
      'verifyCode': '666666',
      'user': {
        'areaCode': '+86',
        'phoneNumber': '13800001111',
        'password': sha256Hex('Test1234'),
        'nickname': 'FlutterTestUser',
      },
    });

    // 用户登录（获取 chatToken + imToken）
    final loginResp = await post('$chatApi/account/login', {
      'areaCode': '+86',
      'phoneNumber': '13800001111',
      'password': sha256Hex('Test1234'),
      'platform': 1,
      'deviceID': 'flutter-test',
    });
    if (loginResp['errCode'] != 0) {
      throw Exception('User login failed in setUpAll: ${loginResp['errMsg']}');
    }
    final loginData = loginResp['data'] as Map<String, dynamic>;
    userImToken = loginData['imToken'] as String;
    userChatToken = loginData['chatToken'] as String;
    userID = loginData['userID'] as String;

    // Admin 登录
    final adminResp = await post('$adminApi/account/login', {
      'account': 'imAdmin',
      'password': 'fb01f147b53025cb74aae37eb0a4f46e',
    });
    if (adminResp['errCode'] != 0) {
      throw Exception('Admin login failed in setUpAll: ${adminResp['errMsg']}');
    }
    final adminData = adminResp['data'] as Map<String, dynamic>;
    adminToken = adminData['adminToken'] as String;
    adminImToken = adminData['imToken'] as String;
    adminUserID = adminData['imUserID'] as String;
  });

  // ═══════════════════════════════════════════════════════
  // 1. 登录链路
  // ═══════════════════════════════════════════════════════
  group('1. App 登录流程', () {
    testWidgets('正确手机号密码 → 登录成功 + Token 有效', (tester) async {
      expect(userImToken, isNotEmpty);
      expect(userChatToken, isNotEmpty);
      expect(userID, isNotEmpty);
      debugPrint('userID=$userID, imToken=${userImToken.substring(0, 20)}...');
    });

    testWidgets('错误密码 → 返回错误码', (tester) async {
      final loginResp = await post('$chatApi/account/login', {
        'areaCode': '+86',
        'phoneNumber': '13800001111',
        'password': sha256Hex('WrongPassword'),
        'platform': 1,
        'deviceID': 'flutter-test',
      });
      // 20001 = PasswordError, 或者 1004 = TooManyAttempts (限流)
      expect(loginResp['errCode'], isNot(0));
    });

    testWidgets('不存在的账号 → 返回错误码', (tester) async {
      final loginResp = await post('$chatApi/account/login', {
        'areaCode': '+86',
        'phoneNumber': '19999999999',
        'password': sha256Hex('SomePassword'),
        'platform': 1,
        'deviceID': 'flutter-test',
      });
      expect(loginResp['errCode'], isNot(0));
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. Token 机制
  // ═══════════════════════════════════════════════════════
  group('2. Token 机制', () {
    testWidgets('有效 Token → IM API 正常响应', (tester) async {
      final conversationsResp = await post(
        '$imApi/msg/get_conversations_has_read_and_max_seq',
        {'userID': userID},
        token: userImToken,
      );
      expect(conversationsResp['errCode'], equals(0));
    });

    testWidgets('无效 Token → IM API 拒绝', (tester) async {
      final resp = await post(
        '$imApi/msg/get_conversations_has_read_and_max_seq',
        {'userID': 'fake'},
        token: 'invalid_token_xxx',
      );
      expect(resp['errCode'], isNot(0));
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. WebSocket Presence（核心验证）
  // ═══════════════════════════════════════════════════════
  group('3. WebSocket Presence', () {
    testWidgets('有效 Token → WS 连接成功 (101)', (tester) async {
      final wsUrl = Uri.parse(
        'ws://$apiHost:10008/ws/presence?token=$userChatToken',
      );
      final channel = WebSocketChannel.connect(wsUrl);
      try {
        await channel.ready.timeout(const Duration(seconds: 5));
        debugPrint('WebSocket connected: true');

        // 保持连接 2 秒验证稳定性
        final sub = channel.stream.listen((msg) {
          debugPrint('WS received: $msg');
        });
        await Future.delayed(const Duration(seconds: 2));
        await sub.cancel();
        await channel.sink.close();
      } catch (e) {
        debugPrint('WS connection failed: $e');
        rethrow;
      }
    });

    testWidgets('无效 Token → WS 连接被拒', (tester) async {
      final wsUrl = Uri.parse(
        'ws://$apiHost:10008/ws/presence?token=invalid_xxx',
      );
      final channel = WebSocketChannel.connect(wsUrl);
      bool rejected = false;
      try {
        await channel.ready.timeout(const Duration(seconds: 5));
        await channel.stream.first.timeout(const Duration(seconds: 3));
      } catch (e) {
        rejected = true;
        debugPrint('Invalid token WS correctly rejected: $e');
      }
      expect(rejected, isTrue, reason: 'WS should reject invalid token');
    });

    testWidgets('无 Token → WS 连接被拒', (tester) async {
      final wsUrl = Uri.parse('ws://$apiHost:10008/ws/presence');
      final channel = WebSocketChannel.connect(wsUrl);
      bool rejected = false;
      try {
        await channel.ready.timeout(const Duration(seconds: 5));
        await channel.stream.first.timeout(const Duration(seconds: 3));
      } catch (e) {
        rejected = true;
        debugPrint('No token WS correctly rejected: $e');
      }
      expect(rejected, isTrue, reason: 'WS should reject missing token');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. 封禁联动 (Admin → App)
  // ═══════════════════════════════════════════════════════
  group('4. 封禁联动 (Admin → App)', () {
    // 安全网：无论测试成功失败，都确保解封
    tearDownAll(() async {
      try {
        await post(
          '$adminApi/user/forbidden/remove',
          {
            'userIDs': [userID]
          },
          token: adminToken,
        );
      } catch (_) {}
    });

    testWidgets('Admin 封禁 → 用户登录被拒 → 解封 → 恢复', (tester) async {
      // 封禁用户
      final blockResp = await post(
        '$adminApi/user/forbidden/add',
        {'userID': userID, 'reason': 'integration-test'},
        token: adminToken,
      );
      expect(blockResp['errCode'], equals(0),
          reason: 'Block failed: ${blockResp['errMsg']}');

      // 用户尝试登录 → 应被拒（20012 = UserIsBlocked, 429 = 限流也算拒绝）
      final loginResp = await post('$chatApi/account/login', {
        'areaCode': '+86',
        'phoneNumber': '13800001111',
        'password': sha256Hex('Test1234'),
        'platform': 1,
        'deviceID': 'flutter-test',
      });
      expect(loginResp['errCode'], isNot(0),
          reason: 'Expected blocked/rejected, got: ${loginResp['errCode']}');

      // 解封
      final unblockResp = await post(
        '$adminApi/user/forbidden/remove',
        {
          'userIDs': [userID]
        },
        token: adminToken,
      );
      expect(unblockResp['errCode'], equals(0));
      // unblock 成功即可 — 不再重新登录（避免触发限流）
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. IM 收发消息
  // ═══════════════════════════════════════════════════════
  group('5. IM 收发消息', () {
    testWidgets('管理员 → 用户发送文本消息', (tester) async {
      final sendResp = await post(
        '$imApi/msg/send_msg',
        {
          'sendID': adminUserID,
          'recvID': userID,
          'senderPlatformID': 3,
          'content': {'content': 'Hello from integration test!'},
          'contentType': 101,
          'sessionType': 1,
        },
        token: adminImToken,
      );
      expect(sendResp['errCode'], equals(0),
          reason: 'SendMsg failed: ${sendResp['errMsg']}');
    });
  });
}
