import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/chat_api.dart';
import '../api/group_api.dart';
import '../models/conversation.dart';
import '../services/im_service.dart';

class ConversationController extends ChangeNotifier {
  List<Conversation> _conversations = [];
  bool _loading = false;
  String _error = '';

  // ─── IM 服务抽象（SDK / HTTP 可切换） ──────────────────────────────
  IMService? _imService;
  StreamSubscription<void>? _convChangedSub;

  /// 注入 IM 服务实现
  void attachIMService(IMService service) {
    _convChangedSub?.cancel();
    _imService = service;
    debugPrint('[ConvCtrl] attached IMService: ${service.name}');
    _convChangedSub = service.onConversationChanged.listen((_) {
      debugPrint('[ConvCtrl] conversation changed, reloading...');
      loadConversations();
    });
  }

  List<Conversation> get conversations => _conversations;
  bool get loading => _loading;
  String get error => _error;

  void debugPrintState() {
    debugPrint(
        '[ConversationController] loading=$_loading conversations=${_conversations.length} error=$_error');
  }

  static dynamic _tryParseJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  /// HTTP 路径：根据 contentType 生成预览文本
  static String _msgPreviewHTTP(int contentType, String content) {
    switch (contentType) {
      case 101: // text
        final m = _tryParseJson(content);
        if (m is Map) return m['content']?.toString() ?? content;
        return content;
      case 106: // atText
        final m = _tryParseJson(content);
        if (m is Map) return m['text']?.toString() ?? '[@消息]';
        return '[@消息]';
      case 102:
        return '[图片]';
      case 103:
        return '[语音]';
      case 104:
        return '[视频]';
      case 105:
        return '[文件]';
      case 109:
        return '[位置]';
      case 114: // quote
        final m = _tryParseJson(content);
        if (m is Map) return m['text']?.toString() ?? '[引用]';
        return '[引用]';
      case 111:
        return '[合并转发]';
      case 112:
      case 113:
        return '[表情]';
      case 2101:
        return '[已撤回]';
      default:
        if (contentType >= 1000) return '[通知]';
        return '[消息]';
    }
  }

  Future<void> loadConversations({int page = 1}) async {
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      if (_imService != null) {
        // ── 通过 IMService 抽象加载（SDK 或 HTTP 包装） ──────────
        debugPrint(
            '[ConversationController] loadConversations via ${_imService!.name}');
        final convs = await _imService!.getConversationList(page: page);
        if (page == 1) {
          _conversations = convs;
        } else {
          _conversations.addAll(convs);
        }
        _enrichOfficialStatus();
      } else {
        // ── 降级：原有 HTTP 直接调用 ──────────────────────────────
        await _loadConversationsHTTP(page: page);
      }
    } catch (e) {
      _error = '加载会话列表失败';
      debugPrint('加载会话列表失败: $e');
    }
    _loading = false;
    notifyListeners();
  }

  /// 原有 HTTP 直接调用路径（降级使用）
  Future<void> _loadConversationsHTTP({int page = 1}) async {
    final res =
        await ConversationApi.getSortedConversationList(pageNumber: page);
    debugPrint(
        '[ConversationController] response errCode=${res['errCode']} dataType=${res['data']?.runtimeType}');
    debugPrint(
        '[ConversationController] data keys=${(res['data'] as Map?)?.keys}');
    final list = res['data']?['conversationElems'] as List? ?? [];
    debugPrint(
        '[ConversationController] conversationElems count=${list.length}');
    final parsed = <Conversation>[];
    for (final e in list) {
      if (e is! Map) continue;
      final elem = Map<String, dynamic>.from(e);
      final msgInfo = elem['msgInfo'] as Map<String, dynamic>? ?? {};
      // 从 conversationID 前缀推断会话类型：si_/sg_
      final convID = elem['conversationID']?.toString() ?? '';
      final sessionType =
          msgInfo['sessionType'] as int? ?? (convID.startsWith('sg_') ? 3 : 1);
      // 对方 userID：单聊时取不是自己的那个 ID
      String userID = '';
      if (sessionType == 1) {
        final sendID = msgInfo['sendID']?.toString() ?? '';
        final recvID = msgInfo['recvID']?.toString() ?? '';
        userID = sendID == ApiConfig.userID ? recvID : sendID;
      }
      final groupID = msgInfo['groupID']?.toString() ?? '';

      // 显示名：单聊用对方 senderName，群聊用 groupName
      String showName = '';
      if (sessionType == 3) {
        showName = msgInfo['groupName']?.toString() ?? '';
      } else {
        showName = msgInfo['senderName']?.toString() ?? '';
      }

      // 提取最新消息内容（根据 contentType 生成预览文本）
      String latestMsg = '';
      final contentType = msgInfo['contentType'] as int? ?? 0;
      final content = msgInfo['content']?.toString() ?? '';
      if (content.isNotEmpty) {
        latestMsg = _msgPreviewHTTP(contentType, content);
      }

      parsed.add(Conversation(
        conversationID: convID,
        conversationType: sessionType,
        userID: userID,
        groupID: groupID,
        showName: showName,
        faceURL: sessionType == 3
            ? (msgInfo['groupFaceURL']?.toString() ?? '')
            : (msgInfo['faceURL']?.toString() ?? ''),
        recvMsgOpt: elem['recvMsgOpt'] as int? ?? 0,
        unreadCount: elem['unreadCount'] as int? ?? 0,
        latestMsg: latestMsg,
        latestMsgSendTime: msgInfo['LatestMsgRecvTime'] as int? ?? 0,
        isPinned: elem['IsPinned'] as bool? ?? false,
      ));
    }
    if (page == 1) {
      _conversations = parsed;
    } else {
      _conversations.addAll(parsed);
    }
    // 后台富化：补充 appRole（1:1 会话对方）和 isOfficialGroup（群会话）
    _enrichOfficialStatus();
  }

  /// 后台查询官方认证状态并更新本地会话对象（不阻塞 UI 渲染）。
  Future<void> _enrichOfficialStatus() async {
    try {
      // 1. 收集所有单聊对方 userID（sessionType == 1）
      final userIDs = _conversations
          .where((c) => c.conversationType == 1 && c.userID.isNotEmpty)
          .map((c) => c.userID)
          .toSet()
          .toList();

      // 2. 收集所有群 ID（sessionType == 3）
      final groupIDs = _conversations
          .where((c) => c.conversationType == 3 && c.groupID.isNotEmpty)
          .map((c) => c.groupID)
          .toSet()
          .toList();

      // 3. 查询用户详情（通过 chat-api /user/find/full）
      final Map<String, int> userAppRoleMap = {};
      final Map<String, int> userIsOfficialMap = {};
      final Map<String, String> userNicknameMap = {};
      final Map<String, String> userFaceURLMap = {};
      if (userIDs.isNotEmpty) {
        try {
          final res =
              await ChatApi.post('/user/find/full', {'userIDs': userIDs});
          final users = res['data']?['users'] as List? ?? [];
          for (final u in users) {
            final id = u['userID']?.toString() ?? '';
            final role = (u['appRole'] ?? 0) as int;
            final official = (u['isOfficial'] ?? 0) as int;
            final nickname = u['nickname']?.toString() ?? '';
            final faceURL = u['faceURL']?.toString() ?? '';
            if (id.isNotEmpty) {
              userAppRoleMap[id] = role;
              userIsOfficialMap[id] = official;
              if (nickname.isNotEmpty) userNicknameMap[id] = nickname;
              if (faceURL.isNotEmpty) userFaceURLMap[id] = faceURL;
            }
          }
        } catch (e) {
          debugPrint('批量获取用户信息失败: $e');
        }
      }

      // 4. 查询群官方状态
      final Map<String, bool> groupOfficialMap = {};
      if (groupIDs.isNotEmpty) {
        try {
          final res = await GroupApi.getGroupOfficialStatus(groupIDs: groupIDs);
          final statuses = res['data']?['statuses'] as Map? ?? {};
          statuses.forEach((k, v) {
            groupOfficialMap[k.toString()] = v == true;
          });
        } catch (e) {
          debugPrint('获取群组官方状态失败: $e');
        }
      }

      // 5. 合并回本地列表
      bool changed = false;
      for (int i = 0; i < _conversations.length; i++) {
        final c = _conversations[i];
        int newAppRole = c.appRole;
        int newIsOfficialUser = c.isOfficialUser;
        bool newIsOfficial = c.isOfficialGroup;
        String newShowName = c.showName;
        String newFaceURL = c.faceURL;
        if (c.conversationType == 1 && c.userID.isNotEmpty) {
          if (userAppRoleMap.containsKey(c.userID)) {
            newAppRole = userAppRoleMap[c.userID]!;
            newIsOfficialUser = userIsOfficialMap[c.userID] ?? 0;
          }
          // 用真实 nickname/faceURL 替换 msgInfo 中的不可靠值
          if (userNicknameMap.containsKey(c.userID)) {
            newShowName = userNicknameMap[c.userID]!;
          }
          if (userFaceURLMap.containsKey(c.userID)) {
            newFaceURL = userFaceURLMap[c.userID]!;
          }
        }
        if (c.conversationType == 3 &&
            groupOfficialMap.containsKey(c.groupID)) {
          newIsOfficial = groupOfficialMap[c.groupID]!;
        }
        if (newAppRole != c.appRole ||
            newIsOfficialUser != c.isOfficialUser ||
            newIsOfficial != c.isOfficialGroup ||
            newShowName != c.showName ||
            newFaceURL != c.faceURL) {
          _conversations[i] = c.copyWith(
            appRole: newAppRole,
            isOfficialUser: newIsOfficialUser,
            isOfficialGroup: newIsOfficial,
            showName: newShowName,
            faceURL: newFaceURL,
          );
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('enrichOfficialStatus 失败: $e');
    }
  }

  Conversation? getById(String id) {
    try {
      return _conversations.firstWhere((c) => c.conversationID == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Pin / Mute ───────────────────────────────────────────────────────────

  Future<void> pinConversation(String conversationID,
      {required bool pinned}) async {
    try {
      await ConversationSettingApi.setConversations(conversations: [
        {'conversationID': conversationID, 'isPinned': pinned},
      ]);
      _updateLocal(conversationID, (c) => c.copyWith(isPinned: pinned));
      _sortConversations();
    } catch (e) {
      debugPrint('置顶会话失败: $e');
    }
  }

  /// recvMsgOpt: 0=正常接收, 2=接收但不通知（静音）
  Future<void> setMuteStatus(String conversationID,
      {required int recvMsgOpt}) async {
    try {
      await ConversationSettingApi.setConversations(conversations: [
        {'conversationID': conversationID, 'recvMsgOpt': recvMsgOpt},
      ]);
      _updateLocal(conversationID, (c) => c.copyWith(recvMsgOpt: recvMsgOpt));
    } catch (e) {
      debugPrint('设置静音失败: $e');
    }
  }

  void _updateLocal(
      String conversationID, Conversation Function(Conversation) update) {
    final idx =
        _conversations.indexWhere((c) => c.conversationID == conversationID);
    if (idx >= 0) {
      _conversations[idx] = update(_conversations[idx]);
      notifyListeners();
    }
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.latestMsgSendTime.compareTo(a.latestMsgSendTime);
    });
    notifyListeners();
  }

  Future<void> clearConversationMessages(String conversationID) async {
    try {
      await MsgApi.clearConversationMsg(conversationIDs: [conversationID]);
    } catch (e) {
      debugPrint('清空聊天记录失败: $e');
    }
  }

  /// 从列表中移除会话（不删除消息记录）
  Future<void> deleteConversation(String conversationID) async {
    try {
      await ConversationSettingApi.deleteConversations(
          conversationIDs: [conversationID]);
      _conversations.removeWhere((c) => c.conversationID == conversationID);
      notifyListeners();
    } catch (e) {
      debugPrint('删除会话失败: $e');
    }
  }

  @override
  void dispose() {
    _convChangedSub?.cancel();
    _conversations.clear();
    super.dispose();
  }
}
