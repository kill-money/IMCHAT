import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as sdk;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/chat_api.dart';
import '../api/media_api.dart';
import '../models/message.dart';
import '../services/im_service.dart';

class ChatController extends ChangeNotifier {
  final Map<String, List<Message>> _messageMap = {};
  String _currentConversationID = '';
  bool _loading = false;

  // ─── IM 服务抽象（SDK / HTTP 可切换） ──────────────────────────────
  IMService? _imService;
  StreamSubscription<MapEntry<String, Message>>? _newMsgSub;
  StreamSubscription<MapEntry<String, String>>? _revokeSub;

  /// 注入 IM 服务实现（由 main.dart 在 HomeWrapper 初始化时调用）
  void attachIMService(IMService service) {
    _imService = service;
    _newMsgSub?.cancel();
    _newMsgSub = service.onNewMessage.listen((entry) {
      addIncomingMessage(entry.key, entry.value);
    });
    _revokeSub?.cancel();
    _revokeSub = service.onMessageRevoked.listen((entry) {
      _handleRemoteRevoke(entry.value);
    });
    debugPrint('[ChatCtrl] attached IMService: ${service.name}');
  }

  // 回复状态
  Message? _replyingTo;

  // 收藏消息 ID 集合（后端持久化 + 本地缓存）
  static const _kStarredKey = 'starred_msg_ids';
  static const _kRetryQueueKey = '_starred_retry_queue';
  final Set<String> _starredMsgIDs = {};

  // 失败重试队列（持久化到 SharedPreferences）
  static const int _maxRetry = 5;
  static const int _maxQueueSize = 200;
  static const int _taskTTLMs = 5 * 60 * 1000; // 5 分钟
  final List<Map<String, dynamic>> _retryQueue = [];
  bool _isRetrying = false;

  ChatController() {
    _loadStarredIDs();
  }

  Future<void> _loadStarredIDs() async {
    // 先从本地缓存快速恢复
    final prefs = await SharedPreferences.getInstance();
    final localIDs = prefs.getStringList(_kStarredKey);
    if (localIDs != null && localIDs.isNotEmpty) {
      _starredMsgIDs.addAll(localIDs);
      notifyListeners();
    }
    // 再从后端同步（以后端为准）
    try {
      final resp = await ChatApi.post('/starred/list', {});
      final ids = (resp['data']?['clientMsgIDs'] as List?)
          ?.map((e) => e.toString())
          .toList();
      if (ids != null) {
        _starredMsgIDs
          ..clear()
          ..addAll(ids);
        _saveStarredLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatController] 后端收藏同步失败，使用本地缓存: $e');
    }
    // 恢复持久化的重试队列
    await _loadRetryQueue();
    if (_retryQueue.isNotEmpty) {
      debugPrint('[STARRED][RETRY] 启动恢复 ${_retryQueue.length} 个待重试任务');
      _scheduleRetry();
    }
  }

  Future<void> _saveStarredLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kStarredKey, _starredMsgIDs.toList());
  }

  Future<void> _saveRetryQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRetryQueueKey, jsonEncode(_retryQueue));
  }

  Future<void> _loadRetryQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kRetryQueueKey);
    if (str != null && str.isNotEmpty) {
      final list = jsonDecode(str) as List;
      _retryQueue.addAll(
        list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          // 兼容旧版格式：path+body → type+clientMsgID
          if (m.containsKey('path') && !m.containsKey('type')) {
            final path = m['path'] as String? ?? '';
            if (path.contains('add')) {
              m['type'] = 'add';
            } else if (path.contains('remove')) {
              m['type'] = 'remove';
            } else if (path.contains('clear')) {
              m['type'] = 'clear';
            } else {
              m['type'] = 'add';
            }
            final body = m['body'] as Map<String, dynamic>?;
            m['clientMsgID'] = body?['clientMsgID'] ?? '';
            m.remove('path');
            m.remove('body');
          }
          // 兼容最旧版本：缺少 type / ts 的裸数据
          if (!m.containsKey('type')) m['type'] = 'add';
          if (!m.containsKey('ts')) {
            m['ts'] = DateTime.now().millisecondsSinceEpoch;
          }
          if (!m.containsKey('clientMsgID')) m['clientMsgID'] = '';
          return m;
        }).toList(),
      );
    }
  }

  String _typePath(String type) {
    switch (type) {
      case 'add':
        return '/starred/add';
      case 'remove':
        return '/starred/remove';
      case 'clear':
        return '/starred/clear';
      default:
        return '/starred/$type';
    }
  }

  void _rollbackUI(String type, String? msgID) {
    if (type == 'clear') {
      // clear 回滚：触发后端重新同步
      _loadStarredIDs();
      return;
    }
    if (msgID == null || msgID.isEmpty) return;
    switch (type) {
      case 'add':
        _starredMsgIDs.remove(msgID);
        break;
      case 'remove':
        _starredMsgIDs.add(msgID);
        break;
    }
    _saveStarredLocal();
    _retryStatus.remove(msgID);
    notifyListeners();
  }

  Future<void> _postWithRetry(String type, String? clientMsgID) async {
    try {
      final path = _typePath(type);
      final body = <String, dynamic>{};
      if (clientMsgID != null && clientMsgID.isNotEmpty) {
        body['clientMsgID'] = clientMsgID;
      }
      final res = await ChatApi.post(path, body);
      final errCode = res['errCode'] as int? ?? 0;
      if (errCode != 0) {
        if (ApiConfig.isTokenError(errCode)) return;
        // LIMIT 错误直接丢弃（不能重试）
        if (errCode == 4001) {
          _rollbackUI(type, clientMsgID);
          return;
        }
        throw Exception('API errCode=$errCode');
      }
    } catch (_) {
      // 去重：同一 clientMsgID 先移除旧任务再入队
      if (clientMsgID != null) {
        _retryQueue.removeWhere((e) => e['clientMsgID'] == clientMsgID);
      }
      debugPrint('[STARRED][RETRY] enqueue $type');
      // 队列上限：丢弃最旧任务
      if (_retryQueue.length >= _maxQueueSize) {
        final old = _retryQueue.removeAt(0);
        final oldID = old['clientMsgID'] as String?;
        if (oldID != null && oldID.isNotEmpty) {
          _retryStatus.remove(oldID);
          _rollbackUI(old['type'] as String? ?? 'add', oldID);
        }
      }
      _retryQueue.add({
        'type': type,
        'clientMsgID': clientMsgID ?? '',
        'retry': 0,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      await _saveRetryQueue();
      if (clientMsgID != null) {
        _retryStatus[clientMsgID] = 0;
        notifyListeners();
      }
      if (!_isRetrying) {
        _scheduleRetry();
      }
    }
  }

  Future<void> _scheduleRetry() async {
    if (_isRetrying) return;
    _isRetrying = true;

    try {
      while (_retryQueue.isNotEmpty && !_disposed) {
        // 网络检查 — 无网络时暂停等待，不浪费 retry 次数
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity.contains(ConnectivityResult.none)) {
          debugPrint('[STARRED][RETRY] no network, waiting 5s');
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        // 取出队首（移除），失败后放回队尾 → 不阻塞后续任务
        final task = _retryQueue.removeAt(0);
        final type = task['type'] as String? ?? 'add';
        final msgID = task['clientMsgID'] as String?;
        final retryCount = (task['retry'] as int?) ?? 0;

        // TTL 过期 → 回滚 UI 并丢弃
        final ts = (task['ts'] as int?) ?? 0;
        if (ts > 0 && DateTime.now().millisecondsSinceEpoch - ts > _taskTTLMs) {
          debugPrint('[STARRED][RETRY] TTL expired, drop $type');
          _rollbackUI(type, msgID);
          await _saveRetryQueue();
          continue;
        }

        // 指数退避（在请求前等待）
        if (retryCount > 0) {
          final delay = Duration(seconds: 1 << retryCount);
          debugPrint('[STARRED][RETRY] backoff ${delay.inSeconds}s');
          await Future.delayed(delay);
        }

        try {
          final path = _typePath(type);
          final body = <String, dynamic>{};
          if (msgID != null && msgID.isNotEmpty) body['clientMsgID'] = msgID;

          final res = await ChatApi.post(path, body);
          final errCode = res['errCode'] as int? ?? 0;

          // Token 过期 → 清空队列，不再重试
          if (ApiConfig.isTokenError(errCode)) {
            debugPrint('[STARRED][RETRY] token expired, clearing queue');
            _retryQueue.clear();
            _retryStatus.clear();
            await _saveRetryQueue();
            notifyListeners();
            break;
          }

          // LIMIT 错误直接丢弃（不能重试）
          if (errCode == 4001) {
            debugPrint('[STARRED][RETRY] limit reached, drop $type');
            _rollbackUI(type, msgID);
            await _saveRetryQueue();
            continue;
          }

          if (errCode == 0) {
            debugPrint('[STARRED][RETRY] success $type');
            if (msgID != null) _retryStatus.remove(msgID);
            await _saveRetryQueue();
            notifyListeners();
            continue;
          }

          // 业务错误，当作失败处理
          throw Exception('API errCode=$errCode');
        } catch (_) {
          // 失败 → 递增重试次数
          final newRetry = retryCount + 1;
          task['retry'] = newRetry;

          if (newRetry >= _maxRetry) {
            debugPrint('[STARRED][RETRY] DROP $type after $_maxRetry attempts');
            // 回滚 UI 状态
            _rollbackUI(type, msgID);
          } else {
            // 放回队尾，不阻塞后续任务
            _retryQueue.add(task);
            if (msgID != null) _retryStatus[msgID] = newRetry;
          }
          notifyListeners();
        }

        await _saveRetryQueue();
      }
    } finally {
      _isRetrying = false;
    }
    await _saveRetryQueue();
  }

  // ─── Retry 可观测状态 ───────────────────────────────────────────────────

  final Map<String, int> _retryStatus = {}; // clientMsgID -> retry count

  int get retryQueueLength => _retryQueue.length;
  int getRetryCount(String msgID) => _retryStatus[msgID] ?? 0;
  bool isRetryingMsg(String msgID) => _retryStatus.containsKey(msgID);

  /// 手动重试：将指定任务提到队首，重置重试计数
  void forceRetry(String msgID) {
    final idx = _retryQueue.indexWhere((e) => e['clientMsgID'] == msgID);
    if (idx == -1) return;
    final task = _retryQueue.removeAt(idx);
    task['retry'] = 0;
    task['ts'] = DateTime.now().millisecondsSinceEpoch;
    _retryQueue.insert(0, task);
    _retryStatus[msgID] = 0;
    notifyListeners();
    if (!_isRetrying) _scheduleRetry();
  }

  // 多选状态
  final Set<String> _selectedMsgIDs = {};
  bool _multiSelectMode = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Message> get currentMessages =>
      _messageMap[_currentConversationID] ?? [];

  /// 过滤掉 reaction 类型消息后的展示列表
  List<Message> get displayMessages => currentMessages
      .where((m) => m.contentType != MessageContentType.reaction)
      .toList();

  /// 聚合 reaction：{targetClientMsgID: {emoji: [senderID, ...]}}
  Map<String, Map<String, List<String>>> get reactionsMap {
    final result = <String, Map<String, List<String>>>{};
    for (final msg in currentMessages) {
      if (msg.contentType != MessageContentType.reaction) continue;
      final rc = msg.reactionContent;
      if (rc == null || rc.reactToMsgID.isEmpty || rc.emoji.isEmpty) continue;
      result[rc.reactToMsgID] ??= {};
      result[rc.reactToMsgID]![rc.emoji] ??= [];
      result[rc.reactToMsgID]![rc.emoji]!.add(msg.sendID);
    }
    return result;
  }

  String get currentConversationID => _currentConversationID;
  bool get loading => _loading;
  Message? get replyingTo => _replyingTo;
  bool get multiSelectMode => _multiSelectMode;
  Set<String> get selectedMsgIDs => Set.unmodifiable(_selectedMsgIDs);

  void debugPrintState() {
    debugPrint(
        '[ChatController] loading=$_loading convID=$_currentConversationID msgs=${_messageMap[_currentConversationID]?.length ?? 0} starred=${_starredMsgIDs.length}');
  }

  bool isStarred(String clientMsgID) => _starredMsgIDs.contains(clientMsgID);

  // ─── Conversation ─────────────────────────────────────────────────────────

  void setConversation(String conversationID) {
    _currentConversationID = conversationID;
    clearMultiSelect();
    _replyingTo = null;
    notifyListeners();
  }

  Future<void> loadHistory({
    required String conversationID,
    int startSeq = 0,
    int endSeq = 0,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      debugPrint(
          '[IM_LOAD] 拉取历史: convID=$conversationID seq=$startSeq→$endSeq (${_imService?.name ?? "HTTP-fallback"})');

      if (_imService != null) {
        // ── 通过 IMService 抽象拉取 ──────────────────────────────
        final result = await _imService!.loadHistory(
          conversationID: conversationID,
          startSeq: startSeq,
          endSeq: endSeq,
        );
        _mergeMessages(conversationID, result.messages);
      } else {
        // ── 降级：直接 HTTP ──────────────────────────────────────
        int begin = startSeq;
        int end = endSeq;

        // begin=0 且 end=0 → 查询 maxSeq 再拉取
        if (begin == 0 && end == 0) {
          final seqRes = await MsgApi.getConversationsHasReadAndMaxSeq(
            conversationIDs: [conversationID],
          );
          final seqInfo = (seqRes['data']?['seqs']
                      as Map<String, dynamic>?)?[conversationID]
                  as Map<String, dynamic>? ??
              {};
          final maxSeq = (seqInfo['maxSeq'] as num?)?.toInt() ?? 0;
          if (maxSeq <= 0) {
            // 服务器无消息 — 仅保留本地待发送消息
            final existing = _messageMap[conversationID] ?? [];
            final pending = existing.where((m) => m.status == 1).toList();
            _messageMap[conversationID] = pending;
            debugPrint('[IM_LOAD] 会话无消息');
            _loading = false;
            notifyListeners();
            return;
          }
          end = maxSeq;
          begin = (maxSeq - 39).clamp(1, maxSeq);
        }

        final res = await MsgApi.pullMsgBySeqs(seqRanges: [
          {
            'conversationID': conversationID,
            'begin': begin,
            'end': end,
          }
        ]);
        final msgsData = res['data']?['msgs'] as Map<String, dynamic>? ?? {};
        final convMsgList = (msgsData[conversationID]?['msgs'] as List?) ?? [];
        final serverMsgs = convMsgList
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
        _mergeMessages(conversationID, serverMsgs);
      }

      debugPrint(
          '[IM_LOAD] 拉到 ${_messageMap[conversationID]?.length ?? 0} 条消息');
      // 标记已读
      _markConversationRead(conversationID);
    } catch (e) {
      debugPrint('[IM_LOAD] 加载历史消息失败: $e');
    }
    _loading = false;
    notifyListeners();
  }

  /// 合并服务端消息和本地消息，保留本地待发送消息，去重已确认消息
  void _mergeMessages(String conversationID, List<Message> serverMsgs) {
    final existing = _messageMap[conversationID] ?? [];
    // 收集本地待发送消息（status==1 发送中，seq==0 还没被服务端确认）
    final pendingLocal =
        existing.where((m) => m.status == 1 && m.seq == 0).toList();

    // 以服务端消息为基础，检查 pending 是否已被服务端返回（按 clientMsgID 匹配）
    final serverIDs = <String>{};
    for (final m in serverMsgs) {
      if (m.clientMsgID.isNotEmpty) serverIDs.add(m.clientMsgID);
      if (m.serverMsgID.isNotEmpty) serverIDs.add(m.serverMsgID);
    }
    final stillPending = pendingLocal.where((m) =>
        !serverIDs.contains(m.clientMsgID) &&
        (m.serverMsgID.isEmpty || !serverIDs.contains(m.serverMsgID)));

    _messageMap[conversationID] = [...serverMsgs, ...stillPending];
  }

  /// 异步标记当前会话最新消息为已读（best-effort，不阻塞 UI）
  void _markConversationRead(String conversationID) {
    final msgs = _messageMap[conversationID];
    if (msgs == null || msgs.isEmpty) return;
    // 收集所有他人消息的 seq
    final seqs = msgs
        .where((m) => m.sendID != ApiConfig.userID && m.seq > 0)
        .map((m) => m.seq)
        .toList();
    if (seqs.isEmpty) return;

    if (_imService != null) {
      _imService!
          .markAsRead(conversationID: conversationID, seqs: seqs)
          .then((_) =>
              debugPrint('[IM_READ] 标记已读: $conversationID ${seqs.length}条'))
          .catchError((Object e) => debugPrint('[IM_READ] 标记已读失败: $e'));
    } else {
      MsgApi.markMsgsAsRead(conversationID: conversationID, seqs: seqs)
          .then((_) {
        debugPrint('[IM_READ] 标记已读: $conversationID ${seqs.length}条');
      }).catchError((Object e) {
        debugPrint('[IM_READ] 标记已读失败: $e');
      });
    }
  }

  // ─── Send messages ────────────────────────────────────────────────────────

  Future<bool> sendTextMessage({
    required String recvID,
    required String text,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.text,
      content: {'content': text},
      sessionType: sessionType,
    );
  }

  Future<bool> sendQuoteMessage({
    required String recvID,
    required String text,
    required Message quoteMsg,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.quote,
      content: QuoteContent(text: text, quoteMessage: quoteMsg).toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送图片消息（imageUrl 为上传后得到的可访问地址）
  Future<bool> sendImageMessage({
    required String recvID,
    required String imageUrl,
    int width = 0,
    int height = 0,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.image,
      content:
          ImageContent(url: imageUrl, width: width, height: height).toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送视频消息
  Future<bool> sendVideoMessage({
    required String recvID,
    required String videoUrl,
    String snapshotUrl = '',
    int duration = 0,
    int videoSize = 0,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.video,
      content: VideoContent(
        videoUrl: videoUrl,
        snapshotUrl: snapshotUrl,
        duration: duration,
        videoSize: videoSize,
      ).toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送文件消息
  Future<bool> sendFileMessage({
    required String recvID,
    required String fileUrl,
    required String fileName,
    int fileSize = 0,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.file,
      content: FileContent(url: fileUrl, fileName: fileName, fileSize: fileSize)
          .toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送语音消息（url 已上传完成后）
  Future<bool> sendVoiceMessage({
    required String recvID,
    required String voiceUrl,
    int duration = 0,
    int dataSize = 0,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.voice,
      content:
          VoiceContent(url: voiceUrl, duration: duration, dataSize: dataSize)
              .toJson(),
      sessionType: sessionType,
    );
  }

  /// 上传媒体文件并发送图片消息（一步完成）
  Future<bool> pickAndSendImage({
    required String recvID,
    required List<int> bytes,
    required String filename,
    int sessionType = 1,
  }) async {
    final tempMsg = _buildTempMessage(
      contentType: MessageContentType.image,
      content: ImageContent(url: '').toJson(),
      recvID: recvID,
      sessionType: sessionType,
    );
    _addTempMessage(tempMsg);

    final url = await MediaApi.uploadFile(bytes: bytes, filename: filename);
    if (url == null) {
      _markFailed(tempMsg.clientMsgID);
      return false;
    }
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.image,
      content: ImageContent(url: url).toJson(),
      sessionType: sessionType,
    );
  }

  /// 上传媒体文件并发送文件消息（一步完成）
  Future<bool> pickAndSendFile({
    required String recvID,
    required List<int> bytes,
    required String filename,
    int sessionType = 1,
  }) async {
    final url = await MediaApi.uploadFile(bytes: bytes, filename: filename);
    if (url == null) return false;
    return sendFileMessage(
      recvID: recvID,
      fileUrl: url,
      fileName: filename,
      fileSize: bytes.length,
      sessionType: sessionType,
    );
  }

  /// 上传语音文件并发送语音消息
  Future<bool> sendVoiceFromFile({
    required String recvID,
    required List<int> bytes,
    required String filename,
    required int durationMs,
    int sessionType = 1,
  }) async {
    final url = await MediaApi.uploadFile(bytes: bytes, filename: filename);
    if (url == null) return false;
    return sendVoiceMessage(
      recvID: recvID,
      voiceUrl: url,
      duration: (durationMs / 1000).round(),
      dataSize: bytes.length,
      sessionType: sessionType,
    );
  }

  /// 发送 Sticker 表情包消息（contentType=112）
  Future<bool> sendSticker({
    required String recvID,
    required String url,
    String name = '',
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.sticker,
      content: StickerContent(url: url, name: name).toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送 GIF 动图消息（contentType=113）
  Future<bool> sendGif({
    required String recvID,
    required String url,
    int width = 180,
    int height = 120,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.gif,
      content: GifContent(url: url, width: width, height: height).toJson(),
      sessionType: sessionType,
    );
  }

  /// 发送消息 Reaction（contentType=116）
  /// [reactToMsgID] — 被回应的消息 clientMsgID；[emoji] — 表情符号如 "👍"
  Future<bool> sendReaction({
    required String recvID,
    required String reactToMsgID,
    required String emoji,
    int sessionType = 1,
  }) {
    return _sendMessage(
      recvID: recvID,
      contentType: MessageContentType.reaction,
      content:
          ReactionContent(reactToMsgID: reactToMsgID, emoji: emoji).toJson(),
      sessionType: sessionType,
    );
  }

  // ─── Message operations ───────────────────────────────────────────────────

  /// 撤回时间限制（2分钟）
  static const _recallTimeLimit = Duration(minutes: 2);

  /// 检查消息是否还能撤回（2分钟内）
  bool canRecall(Message msg) {
    if (msg.sendID != ApiConfig.userID) {
      debugPrint(
          '[canRecall] sendID mismatch: ${msg.sendID} != ${ApiConfig.userID}');
      return false;
    }
    final sent = DateTime.fromMillisecondsSinceEpoch(msg.sendTime);
    final diff = DateTime.now().difference(sent);
    final ok = diff <= _recallTimeLimit;
    debugPrint(
        '[canRecall] sendTime=${msg.sendTime} sent=$sent diff=$diff limit=$_recallTimeLimit ok=$ok');
    return ok;
  }

  /// 撤回消息（仅发送方可操作，2分钟内有效）
  Future<bool> revokeMessage({
    required String conversationID,
    required int seq,
    required String clientMsgID,
  }) async {
    // 客户端预检时间限制
    final msgs = _messageMap[conversationID];
    if (msgs != null) {
      final msg = msgs.where((m) => m.clientMsgID == clientMsgID).firstOrNull;
      if (msg != null && !canRecall(msg)) {
        debugPrint('撤回失败：超过2分钟');
        return false;
      }
    }
    try {
      if (_imService != null && MsgApi.useSDK) {
        // SDK 模式直接调用原生撤回
        await sdk.OpenIM.iMManager.messageManager.revokeMessage(
          conversationID: conversationID,
          clientMsgID: clientMsgID,
        );
      } else {
        // HTTP 模式走 chat-api 撤回（后端校验发送方身份 + 2分钟窗口）
        final msg =
            msgs?.where((m) => m.clientMsgID == clientMsgID).firstOrNull;
        final resp = await ChatMsgApi.recallMessage(
          conversationID: conversationID,
          seq: seq,
          senderID: ApiConfig.userID,
          sendTime: msg?.sendTime ?? 0,
        );
        if (resp['errCode'] != null && resp['errCode'] != 0) {
          debugPrint('撤回消息被拒绝: ${resp['errMsg']}');
          return false;
        }
      }
      if (msgs != null) {
        final idx = msgs.indexWhere((m) => m.clientMsgID == clientMsgID);
        if (idx >= 0) {
          msgs[idx] = msgs[idx].copyWith(
            contentType: MessageContentType.revoke,
            content: {'text': '消息已被撤回'},
            status: 2,
          );
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint('撤回消息失败: $e');
      return false;
    }
  }

  /// 处理远端撤回通知（对方撤回了某条消息）
  void _handleRemoteRevoke(String clientMsgID) {
    for (final entry in _messageMap.entries) {
      final idx = entry.value.indexWhere((m) => m.clientMsgID == clientMsgID);
      if (idx >= 0) {
        entry.value[idx] = entry.value[idx].copyWith(
          contentType: MessageContentType.revoke,
          content: {'text': '消息已被撤回'},
          status: 2,
        );
        debugPrint('[IM_REVOKE] 远端撤回: $clientMsgID in ${entry.key}');
        notifyListeners();
        return;
      }
    }
  }

  /// 编辑消息（仅发送方，文本消息）
  Future<bool> editMessage({
    required String conversationID,
    required String clientMsgID,
    required String newText,
  }) async {
    final msgs = _messageMap[conversationID];
    if (msgs == null) return false;
    final idx = msgs.indexWhere((m) => m.clientMsgID == clientMsgID);
    if (idx < 0) return false;
    final msg = msgs[idx];
    if (msg.sendID != ApiConfig.userID || !msg.isText) return false;

    try {
      // 后端校验（发送方身份 + 2分钟窗口 + 内容过滤）
      final resp = await ChatMsgApi.editMessage(
        conversationID: conversationID,
        messageID: msg.clientMsgID,
        senderID: msg.sendID,
        newContent: newText,
        sendTime: msg.sendTime,
        groupID: msg.groupID,
      );
      if (resp['errCode'] != null && resp['errCode'] != 0) {
        debugPrint('编辑消息被拒绝: ${resp['errMsg']}');
        return false;
      }
      // 后端通过后更新本地消息
      msgs[idx] = msg.copyWith(
        content: {'text': newText},
        isEdited: true,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('编辑消息失败: $e');
      return false;
    }
  }

  /// 群主删除他人消息（服务端删除）
  Future<bool> deleteGroupMessage({
    required String conversationID,
    required String clientMsgID,
    required String groupID,
  }) async {
    final msgs = _messageMap[conversationID];
    if (msgs == null) return false;
    try {
      final msg = msgs.firstWhere((m) => m.clientMsgID == clientMsgID);
      // 后端校验权限（群主/管理员）并执行删除
      final resp = await ChatMsgApi.deleteGroupMessage(
        conversationID: conversationID,
        groupID: groupID,
        seqs: [msg.seq],
        operatorID: ApiConfig.userID,
      );
      if (resp['errCode'] != null && resp['errCode'] != 0) {
        debugPrint('删除群消息被拒绝: ${resp['errMsg']}');
        return false;
      }
      _messageMap[conversationID]
          ?.removeWhere((m) => m.clientMsgID == clientMsgID);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('删除群消息失败: $e');
      return false;
    }
  }

  /// 删除消息（仅对自己，不影响对方）
  Future<bool> deleteMessageForSelf({
    required String conversationID,
    required List<String> clientMsgIDs,
  }) async {
    final msgs = _messageMap[conversationID];
    if (msgs == null) return false;
    final seqs = msgs
        .where((m) => clientMsgIDs.contains(m.clientMsgID))
        .map((m) => m.seq)
        .toList();
    try {
      await MsgApi.deleteMsg(conversationID: conversationID, seqs: seqs);
      _messageMap[conversationID]
          ?.removeWhere((m) => clientMsgIDs.contains(m.clientMsgID));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('删除消息失败: $e');
      return false;
    }
  }

  // ─── Star / Bookmark ──────────────────────────────────────────────────────

  Future<void> starMessage(String clientMsgID) async {
    _starredMsgIDs.add(clientMsgID);
    _saveStarredLocal();
    notifyListeners();
    _postWithRetry('add', clientMsgID);
  }

  Future<void> unstarMessage(String clientMsgID) async {
    _starredMsgIDs.remove(clientMsgID);
    _saveStarredLocal();
    notifyListeners();
    _postWithRetry('remove', clientMsgID);
  }

  void toggleStar(String clientMsgID) {
    if (_starredMsgIDs.contains(clientMsgID)) {
      unstarMessage(clientMsgID);
    } else {
      starMessage(clientMsgID);
    }
  }

  Future<void> clearAllStarred() async {
    _starredMsgIDs.clear();
    _saveStarredLocal();
    notifyListeners();
    _postWithRetry('clear', null);
  }

  /// 所有会话消息的扁平列表（用于「我的收藏」页面）
  List<Message> get allMessages =>
      _messageMap.values.expand((list) => list).toList();

  // ─── Reply ────────────────────────────────────────────────────────────────

  void setReplyingTo(Message? msg) {
    _replyingTo = msg;
    notifyListeners();
  }

  // ─── Multi-select ─────────────────────────────────────────────────────────

  void enterMultiSelectMode(String firstMsgID) {
    _multiSelectMode = true;
    _selectedMsgIDs
      ..clear()
      ..add(firstMsgID);
    notifyListeners();
  }

  void toggleSelect(String clientMsgID) {
    if (_selectedMsgIDs.contains(clientMsgID)) {
      _selectedMsgIDs.remove(clientMsgID);
    } else {
      _selectedMsgIDs.add(clientMsgID);
    }
    notifyListeners();
  }

  void clearMultiSelect() {
    _multiSelectMode = false;
    _selectedMsgIDs.clear();
    notifyListeners();
  }

  // ─── Incoming messages (from polling / WebSocket) ──────────────────────────

  /// 新消息到达时的回调（由 onNewMessage 注入）
  void Function(String conversationID, Message msg)? onNewMessageCallback;

  void addIncomingMessage(String conversationID, Message msg) {
    _messageMap[conversationID] ??= [];
    final msgs = _messageMap[conversationID]!;

    // 防止轮询重复注入：匹配 clientMsgID 或 serverMsgID 或 seq
    if (msgs.any((m) =>
        m.clientMsgID == msg.clientMsgID ||
        (msg.serverMsgID.isNotEmpty && m.serverMsgID == msg.serverMsgID) ||
        (msg.seq > 0 && m.seq == msg.seq))) {
      return;
    }
    debugPrint(
        '[IM_RECV] 收到消息: conv=$conversationID from=${msg.sendID} type=${msg.contentType}');
    _messageMap[conversationID]!.add(msg);

    // 通知新消息回调（用于声音提示等）
    if (msg.sendID != ApiConfig.userID) {
      onNewMessageCallback?.call(conversationID, msg);
    }

    // 如果当前正在查看此会话，自动标记已读
    if (conversationID == _currentConversationID &&
        msg.sendID != ApiConfig.userID &&
        msg.seq > 0) {
      if (_imService != null) {
        _imService!.markAsRead(
            conversationID: conversationID,
            seqs: [msg.seq]).catchError((Object e) {
          debugPrint('[IM_READ] 标记新消息已读失败: $e');
        });
      } else {
        MsgApi.markMsgsAsRead(conversationID: conversationID, seqs: [msg.seq])
            .then((_) {})
            .catchError((Object e) {
          debugPrint('[IM_READ] 标记新消息已读失败: $e');
        });
      }
    }
    notifyListeners();
  }

  /// 转发消息到指定会话
  Future<bool> forwardMessage({
    required Message message,
    required String targetRecvID,
    required int targetSessionType,
  }) {
    return _sendMessage(
      recvID: targetRecvID,
      contentType: message.contentType,
      content: message.content,
      sessionType: targetSessionType,
    );
  }

  /// 合并转发 — 将多条选中消息打包为一条合并转发消息
  Future<bool> mergeForwardMessages({
    required String conversationID,
    required String targetRecvID,
    required int targetSessionType,
    required String title,
  }) async {
    final msgs = _messageMap[conversationID];
    if (msgs == null || _selectedMsgIDs.isEmpty) return false;

    // 取出选中消息，按 sendTime 排序
    final selected = msgs
        .where((m) => _selectedMsgIDs.contains(m.clientMsgID))
        .toList()
      ..sort((a, b) => a.sendTime.compareTo(b.sendTime));
    if (selected.isEmpty) return false;

    // 生成摘要
    final abstractList = selected.take(4).map((m) {
      final name = m.senderNickname.isNotEmpty ? m.senderNickname : m.sendID;
      return '$name: ${m.previewText}';
    }).toList();

    final mergeContent = {
      'title': title,
      'abstractList': abstractList,
      'multiMessage': selected.map((m) => m.toJson()).toList(),
    };

    clearMultiSelect();
    return _sendMessage(
      recvID: targetRecvID,
      contentType: MessageContentType.merge,
      content: mergeContent,
      sessionType: targetSessionType,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<bool> _sendMessage({
    required String recvID,
    required int contentType,
    required dynamic content,
    int sessionType = 1,
  }) async {
    final tempMsg = _buildTempMessage(
      recvID: recvID,
      contentType: contentType,
      content: content,
      sessionType: sessionType,
    );
    _addTempMessage(tempMsg);

    try {
      // ── 通过 IMService 抽象发送（SDK 或 HTTP） ──────────────────
      final SendResult result;
      if (_imService != null) {
        result = await _imService!.sendRawMessage(
          recvID: recvID,
          contentType: contentType,
          content: content,
          sessionType: sessionType,
        );
      } else {
        // 降级：直接调用 HTTP API
        final resp = await MsgApi.sendMsg(
          sendID: ApiConfig.userID,
          recvID: recvID,
          sessionType: sessionType,
          contentType: contentType,
          content: content,
        );
        final errCode = (resp['errCode'] ?? 0) as int;
        result = errCode == 0
            ? SendResult(
                success: true,
                serverMsgID: resp['data']?['serverMsgID']?.toString(),
                sendTime: resp['data']?['sendTime'] as int?,
              )
            : SendResult(
                success: false,
                errorMsg: resp['errMsg']?.toString() ?? 'send failed',
              );
      }

      if (!result.success) {
        debugPrint('[IM_SEND] 发送失败: ${result.errorMsg}');
        _markFailed(tempMsg.clientMsgID);
        return false;
      }
      debugPrint(
          '[IM_SEND] 发送成功: recvID=$recvID contentType=$contentType (${_imService?.name ?? "HTTP-fallback"})');
      _markSent(tempMsg.clientMsgID, {
        'serverMsgID': result.serverMsgID ?? '',
        'sendTime': result.sendTime ?? tempMsg.sendTime,
      });
      return true;
    } catch (e) {
      debugPrint('[IM_SEND] 发送消息异常: $e');
      _markFailed(tempMsg.clientMsgID);
      return false;
    }
  }

  Message _buildTempMessage({
    required String recvID,
    required int contentType,
    required dynamic content,
    int sessionType = 1,
  }) {
    return Message(
      clientMsgID: DateTime.now().millisecondsSinceEpoch.toString(),
      sendID: ApiConfig.userID,
      recvID: recvID,
      contentType: contentType,
      content: content,
      sendTime: DateTime.now().millisecondsSinceEpoch,
      sessionType: sessionType,
      status: 1,
    );
  }

  void _addTempMessage(Message msg, {String? conversationID}) {
    final convID = conversationID ?? _currentConversationID;
    _messageMap[convID] ??= [];
    _messageMap[convID]!.add(msg);
    notifyListeners();
  }

  /// 标记消息为已发送（status=2），并填充服务端返回的 serverMsgID / seq。
  void _markSent(String clientMsgID, dynamic respData,
      {String? conversationID}) {
    final convID = conversationID ?? _currentConversationID;
    final msgs = _messageMap[convID];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.clientMsgID == clientMsgID);
    if (idx >= 0) {
      final serverMsgID =
          (respData is Map ? respData['serverMsgID'] : null)?.toString() ?? '';
      final sendTime =
          (respData is Map ? respData['sendTime'] : null) as int? ??
              msgs[idx].sendTime;
      msgs[idx] = msgs[idx]
          .copyWith(status: 2, serverMsgID: serverMsgID, sendTime: sendTime);
      notifyListeners();
    }
  }

  void _markFailed(String clientMsgID, {String? conversationID}) {
    final convID = conversationID ?? _currentConversationID;
    final msgs = _messageMap[convID];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.clientMsgID == clientMsgID);
    if (idx >= 0) {
      msgs[idx] = msgs[idx].copyWith(status: 3);
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _isRetrying = false;
    _retryQueue.clear();
    _retryStatus.clear();
    _messageMap.clear();
    _newMsgSub?.cancel();
    _revokeSub?.cancel();
    super.dispose();
  }
}
