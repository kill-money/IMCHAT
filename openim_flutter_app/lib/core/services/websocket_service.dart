/// WebSocket 服务 — 连接 Presence Gateway (ws://host:10008/ws/presence)。
///
/// 职责：
///   1. 建立 / 重连 Presence WebSocket（认证通过 ?token={chatToken} 查询参数）
///   2. 每 30 秒发送心跳，维持连接（服务端 readDeadline 90s）
///   3. 解析服务端广播的 `user_status_change` 事件（JSON 文本帧）
///   4. 通过回调通知 StatusController 更新状态缓存
///
/// 与 OpenIM 原生 WS (10001) 无关，该连接由 OpenIM SDK 独立管理。
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';

typedef StatusChangeCallback = void Function(String userID, String status);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _intentionalClose = false;
  int _reconnectDelay = 2; // 秒，指数退避

  /// 状态变化事件回调（由 StatusController 注册）
  StatusChangeCallback? onStatusChange;

  /// WS 重连成功回调（由 StatusController 注册，用于补偿丢失事件）
  VoidCallback? onReconnect;

  bool get isConnected => _channel != null;

  /// 登录后调用，开始连接并维持心跳。
  void connect() {
    _intentionalClose = false;
    _reconnectDelay = 2;
    _open();
  }

  /// 登出时调用，断开连接。
  void disconnect() {
    _intentionalClose = true;
    _cleanup();
  }

  Future<void> _open() async {
    if (ApiConfig.userID.isEmpty || ApiConfig.chatToken.isEmpty) return;
    final isReconnect = _reconnectDelay > 2;
    try {
      // Presence Gateway 通过 ?token=<chatToken> 进行鉴权
      final uri = Uri.parse(ApiConfig.presenceWsUrl)
          .replace(queryParameters: {'token': ApiConfig.chatToken});
      _channel = WebSocketChannel.connect(uri);

      // 等待握手完成；若服务端未升级协议则此处抛出 WebSocketChannelException
      await _channel!.ready;

      // 重连后通知 StatusController 补偿拉取
      if (isReconnect) onReconnect?.call();
      _reconnectDelay = 2; // 重置退避计时器

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _startHeartbeat();
    } catch (e) {
      // 不打印 $e，因为 WebSocketChannel 异常可能包含含 token 的 URI
      if (kDebugMode) debugPrint('[WS] 连接失败');
      _channel?.sink.close();
      _channel = null;
      if (!_intentionalClose) _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final event = map['event']?.toString();
      if (event == 'user_status_change') {
        final userID = map['userID']?.toString() ?? '';
        final status = map['status']?.toString() ?? 'offline';
        if (userID.isNotEmpty) {
          onStatusChange?.call(userID, status);
        }
      }
    } catch (_) {
      // 非 JSON 帧（如 protobuf 消息帧）忽略即可
    }
  }

  void _onError(Object error) {
    if (kDebugMode) debugPrint('[WS] 错误: $error');
    _cleanup();
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _onDone() {
    if (kDebugMode) debugPrint('[WS] 连接关闭');
    _cleanup();
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // 发送任意文本即可让服务端重置 readDeadline（Pong 由 Gorilla 处理）
      _send({'event': 'heartbeat'});
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _reconnectDelay;
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60);
    _reconnectTimer = Timer(Duration(seconds: delay), _open);
    if (kDebugMode) debugPrint('[WS] $delay 秒后重连…');
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[WS] 发送消息失败: $e');
    }
  }
}
