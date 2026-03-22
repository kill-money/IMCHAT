import 'dart:async';
import 'dart:io' show Directory, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';

/// OpenIM SDK 单例封装。
///
/// 职责：
/// 1. SDK 初始化（`initSDK`）
/// 2. 登录 / 登出
/// 3. 消息流暴露（`onNewMessage`）
/// 4. 连接状态管理
///
/// Web 平台不支持原生 SDK，自动跳过。
class IMSDKService extends ChangeNotifier {
  // ─── 单例 ──────────────────────────────────────────────────────────
  static final IMSDKService instance = IMSDKService._();
  IMSDKService._();

  // ─── 状态 ──────────────────────────────────────────────────────────
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  String? _currentUserID;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnecting => _isConnecting;

  /// 原生 SDK 仅支持 Android / iOS / Windows / macOS / Linux。
  bool get isSupported => !kIsWeb;

  // ─── Streams ───────────────────────────────────────────────────────
  final _messageController = StreamController<Message>.broadcast();
  Stream<Message> get onNewMessage => _messageController.stream;

  final _revokedController = StreamController<RevokedInfo>.broadcast();
  Stream<RevokedInfo> get onMessageRevoked => _revokedController.stream;

  // 会话变更通知（同步完成 / 新增会话 / 会话变更）
  final _conversationChangedController = StreamController<void>.broadcast();
  Stream<void> get onConversationChanged =>
      _conversationChangedController.stream;

  // 连接状态码: 0=connecting, 1=connected, -1=failed
  final _connectStateController = StreamController<int>.broadcast();
  Stream<int> get onConnectState => _connectStateController.stream;

  // 好友申请事件（收到新申请 / 被接受 / 被拒绝）
  final _friendApplicationController =
      StreamController<FriendApplicationInfo>.broadcast();
  Stream<FriendApplicationInfo> get onFriendApplicationChanged =>
      _friendApplicationController.stream;

  // 好友列表变更事件（新增/删除好友）
  final _friendChangedController = StreamController<void>.broadcast();
  Stream<void> get onFriendChanged => _friendChangedController.stream;

  // ─── 初始化 ────────────────────────────────────────────────────────
  /// 初始化 SDK。应在 `main()` 中调用一次。
  Future<bool> init() async {
    if (!isSupported) {
      debugPrint('[IMSDK] 当前平台不支持原生 SDK，跳过初始化');
      return false;
    }
    if (_isInitialized) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/openim_sdk';
      await Directory(dataDir).create(recursive: true);

      await OpenIM.iMManager.initSDK(
        platformID: _getPlatformID(),
        apiAddr: ApiConfig.imApiBase,
        wsAddr: ApiConfig.wsUrl,
        dataDir: dataDir,
        logLevel: kDebugMode ? 6 : 1,
        listener: OnConnectListener(
          onConnectSuccess: () {
            debugPrint('[IMSDK] 连接成功');
            _connectStateController.add(1);
          },
          onConnecting: () {
            debugPrint('[IMSDK] 连接中...');
            _connectStateController.add(0);
          },
          onConnectFailed: (code, errorMsg) {
            debugPrint('[IMSDK] 连接失败: $code $errorMsg');
            _connectStateController.add(-1);
          },
          onUserTokenExpired: () {
            debugPrint('[IMSDK] Token 过期');
            _isLoggedIn = false;
            _safeNotify();
            ApiConfig.handleTokenExpired();
          },
          onKickedOffline: () {
            debugPrint('[IMSDK] 被踢下线');
            _isLoggedIn = false;
            _safeNotify();
            ApiConfig.handleTokenExpired();
          },
        ),
      );

      // ── 消息监听 ──────────────────────────────────────────────────
      OpenIM.iMManager.messageManager.setAdvancedMsgListener(
        OnAdvancedMsgListener(
          onRecvNewMessage: (Message msg) {
            debugPrint(
                '[IMSDK] 收到新消息: sendID=${msg.sendID} type=${msg.contentType}');
            _messageController.add(msg);
          },
          onNewRecvMessageRevoked: (RevokedInfo info) {
            debugPrint('[IMSDK] 收到撤回通知: clientMsgID=${info.clientMsgID}');
            _revokedController.add(info);
          },
        ),
      );

      // ── 好友关系监听 ──────────────────────────────────────────────
      OpenIM.iMManager.friendshipManager.setFriendshipListener(
        OnFriendshipListener(
          onFriendApplicationAdded: (info) {
            debugPrint('[IMSDK] 收到好友申请: from=${info.fromUserID}');
            _friendApplicationController.add(info);
          },
          onFriendApplicationAccepted: (info) {
            debugPrint('[IMSDK] 好友申请已被接受: ${info.fromUserID}');
            _friendApplicationController.add(info);
            _friendChangedController.add(null);
          },
          onFriendApplicationRejected: (info) {
            debugPrint('[IMSDK] 好友申请已被拒绝: ${info.fromUserID}');
            _friendApplicationController.add(info);
          },
          onFriendAdded: (info) {
            debugPrint('[IMSDK] 新增好友: ${info.userID}');
            _friendChangedController.add(null);
          },
          onFriendDeleted: (info) {
            debugPrint('[IMSDK] 删除好友: ${info.userID}');
            _friendChangedController.add(null);
          },
        ),
      );

      // ── 会话监听 ──────────────────────────────────────────────────
      OpenIM.iMManager.conversationManager.setConversationListener(
        OnConversationListener(
          onSyncServerStart: (_) => debugPrint('[IMSDK] 数据同步开始'),
          onSyncServerFinish: (_) {
            debugPrint('[IMSDK] 数据同步完成');
            _conversationChangedController.add(null);
          },
          onSyncServerFailed: (_) => debugPrint('[IMSDK] 数据同步失败'),
          onNewConversation: (list) {
            debugPrint('[IMSDK] 新增会话: ${list.length}');
            _conversationChangedController.add(null);
          },
          onConversationChanged: (list) {
            debugPrint('[IMSDK] 会话变更: ${list.length}');
            _conversationChangedController.add(null);
          },
        ),
      );

      _isInitialized = true;
      debugPrint('[IMSDK] 初始化成功 (platform=${_getPlatformID()})');
      return true;
    } catch (e) {
      debugPrint('[IMSDK] 初始化失败: $e');
      return false;
    }
  }

  // ─── 登录 / 登出 ──────────────────────────────────────────────────
  /// 使用 userID + imToken 登录 SDK。
  Future<bool> login(String userID, String token) async {
    if (!_isInitialized) {
      debugPrint('[IMSDK] 尚未初始化，无法登录');
      return false;
    }
    if (_isLoggedIn && _currentUserID == userID) return true;

    _isConnecting = true;
    _safeNotify();

    try {
      await OpenIM.iMManager.login(userID: userID, token: token);
      _currentUserID = userID;
      _isLoggedIn = true;
      _isConnecting = false;
      _safeNotify();
      debugPrint('[IMSDK] 登录成功: $userID');
      return true;
    } catch (e) {
      debugPrint('[IMSDK] 登录失败: $e');
      _isConnecting = false;
      _safeNotify();
      return false;
    }
  }

  /// 登出 SDK。
  Future<void> logout() async {
    if (!_isLoggedIn) return;
    try {
      await OpenIM.iMManager.logout();
    } catch (e) {
      debugPrint('[IMSDK] 登出异常: $e');
    } finally {
      _isLoggedIn = false;
      _currentUserID = null;
      _safeNotify();
      debugPrint('[IMSDK] 已登出');
    }
  }

  // ─── 消息收发 ──────────────────────────────────────────────────────
  /// 发送文本消息（单聊传 userID，群聊传 groupID）。
  Future<Message?> sendTextMessage({
    required String text,
    String? userID,
    String? groupID,
  }) async {
    if (!_isLoggedIn) return null;

    try {
      final message =
          await OpenIM.iMManager.messageManager.createTextMessage(text: text);
      final result = await OpenIM.iMManager.messageManager.sendMessage(
        message: message,
        userID: userID,
        groupID: groupID,
        offlinePushInfo: OfflinePushInfo(),
      );
      return result;
    } catch (e) {
      debugPrint('[IMSDK] 发送消息失败: $e');
      return null;
    }
  }

  // ─── 会话 ──────────────────────────────────────────────────────────
  /// 分页获取会话列表。
  Future<List<ConversationInfo>> getConversationList({
    int offset = 0,
    int count = 100,
  }) async {
    if (!_isLoggedIn) return [];
    try {
      return await OpenIM.iMManager.conversationManager
          .getConversationListSplit(offset: offset, count: count);
    } catch (e) {
      debugPrint('[IMSDK] 获取会话列表失败: $e');
      return [];
    }
  }

  /// 获取历史消息。
  Future<AdvancedMessage?> getHistoryMessageList({
    required String conversationID,
    int count = 20,
    Message? startMsg,
  }) async {
    if (!_isLoggedIn) return null;
    try {
      return await OpenIM.iMManager.messageManager
          .getAdvancedHistoryMessageList(
        conversationID: conversationID,
        count: count,
        startMsg: startMsg,
      );
    } catch (e) {
      debugPrint('[IMSDK] 获取历史消息失败: $e');
      return null;
    }
  }

  /// 标记会话已读。
  Future<void> markConversationRead(String conversationID) async {
    if (!_isLoggedIn) return;
    try {
      await OpenIM.iMManager.conversationManager
          .markConversationMessageAsRead(conversationID: conversationID);
    } catch (e) {
      debugPrint('[IMSDK] 标记已读失败: $e');
    }
  }

  // ─── 内部工具 ──────────────────────────────────────────────────────
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  int _getPlatformID() {
    if (kIsWeb) return 5;
    if (Platform.isAndroid) return 2;
    if (Platform.isIOS) return 1;
    if (Platform.isWindows) return 3;
    if (Platform.isMacOS) return 4;
    if (Platform.isLinux) return 7;
    return 2;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.close();
    _revokedController.close();
    _conversationChangedController.close();
    _connectStateController.close();
    _friendApplicationController.close();
    _friendChangedController.close();
    super.dispose();
  }
}
