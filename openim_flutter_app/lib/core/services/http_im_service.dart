/// HTTP 路径的 IMService 实现 — 封装现有 MsgApi / ConversationApi。
///
/// 这是 `useSDK = false` 时的默认实现，保持与原有代码完全一致的 HTTP 调用链。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/chat_api.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'im_service.dart';

class HTTPIMService implements IMService {
  final _newMessageController =
      StreamController<MapEntry<String, Message>>.broadcast();
  bool _disposed = false;

  @override
  String get name => 'HTTP';

  // ─── 消息发送 ──────────────────────────────────────────────────────

  @override
  Future<SendResult> sendTextMessage({
    required String recvID,
    required String text,
    int sessionType = 1,
  }) =>
      sendRawMessage(
        recvID: recvID,
        contentType: MessageContentType.text,
        content: {'content': text},
        sessionType: sessionType,
      );

  @override
  Future<SendResult> sendImageMessage({
    required String recvID,
    required String imageUrl,
    int width = 0,
    int height = 0,
    int sessionType = 1,
  }) {
    final pic = {
      'url': imageUrl,
      'width': width,
      'height': height,
      'type': 'jpg',
      'size': 0,
    };
    return sendRawMessage(
      recvID: recvID,
      contentType: MessageContentType.image,
      content: {
        'bigPicture': pic,
        'snapshotPicture': pic,
        'sourcePicture': pic,
      },
      sessionType: sessionType,
    );
  }

  @override
  Future<SendResult> sendVideoMessage({
    required String recvID,
    required String videoUrl,
    String snapshotUrl = '',
    int duration = 0,
    int videoSize = 0,
    int sessionType = 1,
  }) =>
      sendRawMessage(
        recvID: recvID,
        contentType: MessageContentType.video,
        content: {
          'videoUrl': videoUrl,
          'snapshotUrl': snapshotUrl,
          'duration': duration,
          'videoSize': videoSize,
          'videoType': 'mp4',
          'videoPath': '',
        },
        sessionType: sessionType,
      );

  @override
  Future<SendResult> sendFileMessage({
    required String recvID,
    required String fileUrl,
    required String fileName,
    int fileSize = 0,
    int sessionType = 1,
  }) =>
      sendRawMessage(
        recvID: recvID,
        contentType: MessageContentType.file,
        content: {
          'url': fileUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          'filePath': '',
        },
        sessionType: sessionType,
      );

  @override
  Future<SendResult> sendVoiceMessage({
    required String recvID,
    required String voiceUrl,
    int duration = 0,
    int dataSize = 0,
    int sessionType = 1,
  }) =>
      sendRawMessage(
        recvID: recvID,
        contentType: MessageContentType.voice,
        content: {
          'sourceUrl': voiceUrl,
          'duration': duration,
          'dataSize': dataSize,
          'soundPath': '',
        },
        sessionType: sessionType,
      );

  @override
  Future<SendResult> sendRawMessage({
    required String recvID,
    required int contentType,
    required dynamic content,
    int sessionType = 1,
  }) async {
    try {
      final resp = await MsgApi.sendMsg(
        sendID: ApiConfig.userID,
        recvID: recvID,
        sessionType: sessionType,
        contentType: contentType,
        content: content,
      );
      final errCode = (resp['errCode'] ?? 0) as int;
      if (errCode != 0) {
        return SendResult(
          success: false,
          errorMsg: resp['errMsg']?.toString() ?? 'send failed',
        );
      }
      final data = resp['data'] as Map<String, dynamic>?;
      return SendResult(
        success: true,
        serverMsgID: data?['serverMsgID']?.toString(),
        sendTime: data?['sendTime'] as int?,
      );
    } catch (e) {
      debugPrint('[HTTPIMService] sendRawMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  // ─── 历史消息 ──────────────────────────────────────────────────────

  @override
  Future<HistoryResult> loadHistory({
    required String conversationID,
    int startSeq = 0,
    int endSeq = 0,
    int count = 40,
  }) async {
    try {
      int begin = startSeq;
      int end = endSeq;

      // begin=0 且 end=0 表示"加载最新消息" — 先查 maxSeq 再计算范围
      if (begin == 0 && end == 0) {
        final seqRes = await MsgApi.getConversationsHasReadAndMaxSeq(
          conversationIDs: [conversationID],
        );
        final seqInfo =
            (seqRes['data']?['seqs'] as Map<String, dynamic>?)?[conversationID]
                    as Map<String, dynamic>? ??
                {};
        final maxSeq = (seqInfo['maxSeq'] as num?)?.toInt() ?? 0;
        if (maxSeq <= 0) {
          return const HistoryResult(messages: []);
        }
        end = maxSeq;
        begin = (maxSeq - count + 1).clamp(1, maxSeq);
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
      final messages = convMsgList
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
      final isEnd = (msgsData[conversationID]?['isEnd'] as bool?) ?? false;
      return HistoryResult(messages: messages, isEnd: isEnd);
    } catch (e) {
      debugPrint('[HTTPIMService] loadHistory error: $e');
      return const HistoryResult(messages: []);
    }
  }

  // ─── 已读 ──────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead({
    required String conversationID,
    required List<int> seqs,
  }) async {
    if (seqs.isEmpty) return;
    try {
      await MsgApi.markMsgsAsRead(conversationID: conversationID, seqs: seqs);
    } catch (e) {
      debugPrint('[HTTPIMService] markAsRead error: $e');
    }
  }

  // ─── 会话列表 ──────────────────────────────────────────────────────

  @override
  Future<List<Conversation>> getConversationList({int page = 1}) async {
    try {
      final resp =
          await ConversationApi.getSortedConversationList(pageNumber: page);
      final elems = (resp['data']?['conversationElems'] as List?) ?? [];
      return elems.map((e) {
        final m = e as Map<String, dynamic>;
        final msgInfo = m['msgInfo'] as Map<String, dynamic>? ?? {};
        return Conversation(
          conversationID: m['conversationID'] ?? '',
          conversationType: msgInfo['sessionType'] ?? 1,
          userID: _extractUserID(m['conversationID'] ?? '', msgInfo),
          groupID: msgInfo['groupID'] ?? '',
          showName: msgInfo['groupName'] ?? msgInfo['senderName'] ?? '',
          faceURL: msgInfo['groupFaceURL'] ?? msgInfo['faceURL'] ?? '',
          recvMsgOpt: m['recvMsgOpt'] ?? 0,
          unreadCount: m['unreadCount'] ?? 0,
          latestMsg: _buildLatestMsgStr(msgInfo),
          latestMsgSendTime:
              m['LatestMsgRecvTime'] ?? m['latestMsgRecvTime'] ?? 0,
          isPinned: m['IsPinned'] ?? m['isPinned'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('[HTTPIMService] getConversationList error: $e');
      return [];
    }
  }

  // ─── 新消息流（HTTP 模式由 ImPollingService 注入） ─────────────────

  @override
  Stream<MapEntry<String, Message>> get onNewMessage =>
      _newMessageController.stream;

  @override
  Stream<MapEntry<String, String>> get onMessageRevoked => const Stream.empty();

  @override
  Stream<void> get onConversationChanged => const Stream.empty();

  /// 供 ImPollingService 从外部注入新消息
  void injectNewMessage(String conversationID, Message msg) {
    if (!_disposed) {
      _newMessageController.add(MapEntry(conversationID, msg));
    }
  }

  // ─── 内部工具 ──────────────────────────────────────────────────────

  String _extractUserID(String convID, Map<String, dynamic> msgInfo) {
    // 优先从 msgInfo 中的 sendID/recvID 提取对方 userID（最可靠）
    if (convID.startsWith('si_')) {
      final sendID = (msgInfo['sendID'] ?? '').toString();
      final recvID = (msgInfo['recvID'] ?? '').toString();
      if (sendID.isNotEmpty || recvID.isNotEmpty) {
        return sendID == ApiConfig.userID ? recvID : sendID;
      }
      // 降级：从 conversationID 解析（si_idA_idB 排序格式）
      final suffix = convID.substring(3); // 去掉 'si_'
      final parts = suffix.split('_');
      if (parts.length == 2) {
        return parts[0] == ApiConfig.userID ? parts[1] : parts[0];
      }
    }
    return (msgInfo['sendID'] ?? '').toString();
  }

  String _buildLatestMsgStr(Map<String, dynamic> msgInfo) {
    try {
      final contentType = msgInfo['contentType'] as int? ?? 0;
      final rawContent = (msgInfo['content'] ?? '').toString();
      switch (contentType) {
        case 101: // text
          final m = _tryParseJson(rawContent);
          if (m is Map) return m['content']?.toString() ?? rawContent;
          return rawContent;
        case 106: // atText
          final m = _tryParseJson(rawContent);
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
          final m = _tryParseJson(rawContent);
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
    } catch (_) {
      return '';
    }
  }

  static dynamic _tryParseJson(String s) {
    try {
      return json.decode(s);
    } catch (_) {
      return null;
    }
  }

  // ─── 生命周期 ──────────────────────────────────────────────────────

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _newMessageController.close();
  }
}
