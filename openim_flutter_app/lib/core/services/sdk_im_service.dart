/// SDK 路径的 IMService 实现 — 委托给 [IMSDKService] 原生 SDK。
///
/// 负责：
/// 1. 将 IMService 接口调用转发给 `flutter_openim_sdk` 原生方法
/// 2. SDK Message ↔ app Message 双向转换
/// 3. SDK ConversationInfo → app Conversation 转换
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as sdk;

import '../api/api_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'im_service.dart';
import 'im_sdk_service.dart';

class SDKIMService implements IMService {
  final IMSDKService _sdk = IMSDKService.instance;
  StreamSubscription<sdk.Message>? _msgSub;
  StreamSubscription<sdk.RevokedInfo>? _revokeSub;
  final _newMessageController =
      StreamController<MapEntry<String, Message>>.broadcast();
  final _revokedController =
      StreamController<MapEntry<String, String>>.broadcast();
  bool _disposed = false;

  /// 每个会话最后加载到的 SDK Message — 用于游标分页
  final Map<String, sdk.Message> _lastMsgCursor = {};

  SDKIMService() {
    // 监听 SDK 收到的新消息 → 转换为 app Message 并推送
    _msgSub = _sdk.onNewMessage.listen((sdkMsg) {
      final appMsg = _convertMessage(sdkMsg);
      // conversationID 优先用 groupID，否则用对方 userID
      final convID = (sdkMsg.groupID?.isNotEmpty == true)
          ? 'sg_${sdkMsg.groupID}'
          : 'si_${sdkMsg.sendID == ApiConfig.userID ? sdkMsg.recvID : sdkMsg.sendID}';
      _newMessageController.add(MapEntry(convID, appMsg));
    });
    // 监听撤回通知 → 推送 clientMsgID
    _revokeSub = _sdk.onMessageRevoked.listen((info) {
      final clientMsgID = info.clientMsgID ?? '';
      if (clientMsgID.isNotEmpty) {
        _revokedController.add(MapEntry('revoke', clientMsgID));
      }
    });
  }

  @override
  String get name => 'SDK';

  // ─── 消息发送 ──────────────────────────────────────────────────────

  @override
  Future<SendResult> sendTextMessage({
    required String recvID,
    required String text,
    int sessionType = 1,
  }) async {
    try {
      final msg = await sdk.OpenIM.iMManager.messageManager
          .createTextMessage(text: text);
      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendTextMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  @override
  Future<SendResult> sendImageMessage({
    required String recvID,
    required String imageUrl,
    int width = 0,
    int height = 0,
    int sessionType = 1,
  }) async {
    try {
      final picInfo = sdk.PictureInfo(
        url: imageUrl,
        width: width,
        height: height,
        type: 'jpg',
      );
      final msg =
          await sdk.OpenIM.iMManager.messageManager.createImageMessageByURL(
        sourcePicture: picInfo,
        bigPicture: picInfo,
        snapshotPicture: picInfo,
      );
      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendImageMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  @override
  Future<SendResult> sendVideoMessage({
    required String recvID,
    required String videoUrl,
    String snapshotUrl = '',
    int duration = 0,
    int videoSize = 0,
    int sessionType = 1,
  }) async {
    try {
      final msg =
          await sdk.OpenIM.iMManager.messageManager.createVideoMessageByURL(
        videoElem: sdk.VideoElem(
          videoUrl: videoUrl,
          snapshotUrl: snapshotUrl,
          duration: duration,
          videoSize: videoSize,
          videoType: 'mp4',
        ),
      );
      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendVideoMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  @override
  Future<SendResult> sendFileMessage({
    required String recvID,
    required String fileUrl,
    required String fileName,
    int fileSize = 0,
    int sessionType = 1,
  }) async {
    try {
      final msg =
          await sdk.OpenIM.iMManager.messageManager.createFileMessageByURL(
        fileElem: sdk.FileElem(
          sourceUrl: fileUrl,
          fileName: fileName,
          fileSize: fileSize,
        ),
      );
      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendFileMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  @override
  Future<SendResult> sendVoiceMessage({
    required String recvID,
    required String voiceUrl,
    int duration = 0,
    int dataSize = 0,
    int sessionType = 1,
  }) async {
    try {
      final msg =
          await sdk.OpenIM.iMManager.messageManager.createSoundMessageByURL(
        soundElem: sdk.SoundElem(
          sourceUrl: voiceUrl,
          duration: duration,
          dataSize: dataSize,
        ),
      );
      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendVoiceMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  @override
  Future<SendResult> sendRawMessage({
    required String recvID,
    required int contentType,
    required dynamic content,
    int sessionType = 1,
  }) async {
    try {
      final contentMap = _toMap(content);
      final sdk.Message msg;

      switch (contentType) {
        case MessageContentType.text:
          final text = contentMap['content']?.toString() ?? '';
          msg = await sdk.OpenIM.iMManager.messageManager
              .createTextMessage(text: text);

        case MessageContentType.image:
          final big =
              contentMap['bigPicture'] as Map<String, dynamic>? ?? contentMap;
          final snap =
              contentMap['snapshotPicture'] as Map<String, dynamic>? ?? big;
          final src =
              contentMap['sourcePicture'] as Map<String, dynamic>? ?? big;
          sdk.PictureInfo toPic(Map<String, dynamic> m) => sdk.PictureInfo(
                url: m['url']?.toString() ?? '',
                width: (m['width'] ?? 0) as int,
                height: (m['height'] ?? 0) as int,
                type: m['type']?.toString() ?? 'jpg',
              );
          msg =
              await sdk.OpenIM.iMManager.messageManager.createImageMessageByURL(
            sourcePicture: toPic(src),
            bigPicture: toPic(big),
            snapshotPicture: toPic(snap),
          );

        case MessageContentType.voice:
          msg =
              await sdk.OpenIM.iMManager.messageManager.createSoundMessageByURL(
            soundElem: sdk.SoundElem(
              sourceUrl: contentMap['sourceUrl']?.toString() ?? '',
              duration: (contentMap['duration'] ?? 0) as int,
              dataSize: (contentMap['dataSize'] ?? 0) as int,
            ),
          );

        case MessageContentType.video:
          msg =
              await sdk.OpenIM.iMManager.messageManager.createVideoMessageByURL(
            videoElem: sdk.VideoElem(
              videoUrl: contentMap['videoUrl']?.toString() ?? '',
              snapshotUrl: contentMap['snapshotUrl']?.toString() ?? '',
              duration: (contentMap['duration'] ?? 0) as int,
              videoSize: (contentMap['videoSize'] ?? 0) as int,
              videoType: contentMap['videoType']?.toString() ?? 'mp4',
            ),
          );

        case MessageContentType.file:
          msg =
              await sdk.OpenIM.iMManager.messageManager.createFileMessageByURL(
            fileElem: sdk.FileElem(
              sourceUrl: contentMap['url']?.toString() ?? '',
              fileName: contentMap['fileName']?.toString() ?? '',
              fileSize: (contentMap['fileSize'] ?? 0) as int,
            ),
          );

        case MessageContentType.quote:
          final text = contentMap['text']?.toString() ?? '';
          final quoteJson = contentMap['quoteMessage'] as Map<String, dynamic>?;
          if (quoteJson != null) {
            final quoteMsg = sdk.Message.fromJson(quoteJson);
            msg = await sdk.OpenIM.iMManager.messageManager
                .createQuoteMessage(text: text, quoteMsg: quoteMsg);
          } else {
            // 无引用原消息时降级为文本
            msg = await sdk.OpenIM.iMManager.messageManager
                .createTextMessage(text: text);
          }

        case MessageContentType.merge:
          final title = contentMap['title']?.toString() ?? '';
          final abstractList = (contentMap['abstractList'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final multiMessage = (contentMap['multiMessage'] as List?) ?? [];
          final sdkMessages = multiMessage
              .map((e) => sdk.Message.fromJson(e as Map<String, dynamic>))
              .toList();
          msg = await sdk.OpenIM.iMManager.messageManager.createMergerMessage(
            messageList: sdkMessages,
            title: title,
            summaryList: abstractList,
          );

        case MessageContentType.location:
          msg = await sdk.OpenIM.iMManager.messageManager.createLocationMessage(
            latitude: (contentMap['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (contentMap['longitude'] as num?)?.toDouble() ?? 0.0,
            description: contentMap['desc']?.toString() ?? '',
          );

        default:
          // sticker / gif / reaction / face / other custom types
          final jsonStr = content is String ? content : json.encode(content);
          msg = await sdk.OpenIM.iMManager.messageManager.createCustomMessage(
            data: jsonStr,
            extension: '',
            description: '',
          );
      }

      return _doSend(msg, recvID, sessionType);
    } catch (e) {
      debugPrint('[SDKIMService] sendRawMessage error: $e');
      return SendResult(success: false, errorMsg: e.toString());
    }
  }

  /// 将 content 參数转为 Map<String, dynamic>
  Map<String, dynamic> _toMap(dynamic content) {
    if (content is Map<String, dynamic>) return content;
    if (content is Map) return Map<String, dynamic>.from(content);
    if (content is String) {
      try {
        final decoded = json.decode(content);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  /// 核心发送 — 调用 SDK sendMessage
  Future<SendResult> _doSend(
      sdk.Message msg, String recvID, int sessionType) async {
    final isGroup = sessionType == 3;
    try {
      final result = await sdk.OpenIM.iMManager.messageManager.sendMessage(
        message: msg,
        userID: isGroup ? null : recvID,
        groupID: isGroup ? recvID : null,
        offlinePushInfo: sdk.OfflinePushInfo(),
      );
      return SendResult(
        success: true,
        serverMsgID: result.serverMsgID ?? '',
        sendTime: result.sendTime ?? DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[SDKIMService] _doSend error: $e');
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
      // startSeq > 0 表示"加载更多"，使用游标分页
      final cursor = startSeq > 0 ? _lastMsgCursor[conversationID] : null;
      final result = await sdk.OpenIM.iMManager.messageManager
          .getAdvancedHistoryMessageList(
        conversationID: conversationID,
        count: count,
        startMsg: cursor,
      );
      final sdkMsgList = result.messageList ?? [];
      if (sdkMsgList.isNotEmpty) {
        _lastMsgCursor[conversationID] = sdkMsgList.last;
      }
      final messages = sdkMsgList.map(_convertMessage).toList();
      return HistoryResult(
        messages: messages,
        isEnd: result.isEnd ?? false,
      );
    } catch (e) {
      debugPrint('[SDKIMService] loadHistory error: $e');
      return const HistoryResult(messages: []);
    }
  }

  // ─── 已读 ──────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead({
    required String conversationID,
    required List<int> seqs,
  }) async {
    try {
      await sdk.OpenIM.iMManager.conversationManager
          .markConversationMessageAsRead(conversationID: conversationID);
    } catch (e) {
      debugPrint('[SDKIMService] markAsRead error: $e');
    }
  }

  // ─── 会话列表 ──────────────────────────────────────────────────────

  @override
  Future<List<Conversation>> getConversationList({int page = 1}) async {
    try {
      final offset = (page - 1) * 100;
      final list = await sdk.OpenIM.iMManager.conversationManager
          .getConversationListSplit(offset: offset, count: 100);
      return list.map(_convertConversation).toList();
    } catch (e) {
      debugPrint('[SDKIMService] getConversationList error: $e');
      return [];
    }
  }

  // ─── 新消息流 ──────────────────────────────────────────────────────

  @override
  Stream<MapEntry<String, Message>> get onNewMessage =>
      _newMessageController.stream;

  @override
  Stream<MapEntry<String, String>> get onMessageRevoked =>
      _revokedController.stream;

  @override
  Stream<void> get onConversationChanged => _sdk.onConversationChanged;

  // ─── 转换：SDK Message → app Message ──────────────────────────────

  Message _convertMessage(sdk.Message m) {
    dynamic content;
    final ct = m.contentType ?? MessageContentType.text;

    switch (ct) {
      case MessageContentType.text:
        content = {'content': m.textElem?.content ?? ''};
        break;
      case MessageContentType.image:
        final p = m.pictureElem;
        content = {
          'bigPicture': _pictureInfoToMap(p?.bigPicture),
          'snapshotPicture': _pictureInfoToMap(p?.snapshotPicture),
          'sourcePicture': _pictureInfoToMap(p?.sourcePicture),
        };
        break;
      case MessageContentType.voice:
        final s = m.soundElem;
        content = {
          'sourceUrl': s?.sourceUrl ?? '',
          'duration': s?.duration ?? 0,
          'dataSize': s?.dataSize ?? 0,
        };
        break;
      case MessageContentType.video:
        final v = m.videoElem;
        content = {
          'videoUrl': v?.videoUrl ?? '',
          'snapshotUrl': v?.snapshotUrl ?? '',
          'duration': v?.duration ?? 0,
          'videoSize': v?.videoSize ?? 0,
        };
        break;
      case MessageContentType.file:
        final f = m.fileElem;
        content = {
          'url': f?.sourceUrl ?? '',
          'fileName': f?.fileName ?? '',
          'fileSize': f?.fileSize ?? 0,
        };
        break;
      case MessageContentType.quote:
        final q = m.quoteElem;
        content = {
          'text': q?.text ?? '',
          if (q?.quoteMessage != null)
            'quoteMessage': _convertMessage(q!.quoteMessage!).toJson(),
        };
        break;
      case MessageContentType.merge:
        final me = m.mergeElem;
        content = {
          'title': me?.title ?? '',
          'abstractList': me?.abstractList ?? [],
          'multiMessage': (me?.multiMessage ?? [])
              .map((e) => _convertMessage(e).toJson())
              .toList(),
        };
        break;
      default:
        // sticker/gif/reaction/custom — 尝试从 customElem 或 ex 获取
        if (m.customElem?.data != null) {
          try {
            content = json.decode(m.customElem!.data!);
          } catch (_) {
            content = m.customElem?.data ?? '';
          }
        } else if (m.faceElem != null) {
          content = {
            'index': m.faceElem?.index ?? 0,
            'data': m.faceElem?.data ?? '',
          };
        } else {
          content = '';
        }
    }

    return Message(
      clientMsgID: m.clientMsgID ?? '',
      serverMsgID: m.serverMsgID ?? '',
      sendID: m.sendID ?? '',
      recvID: m.recvID ?? '',
      groupID: m.groupID ?? '',
      senderPlatformID: m.senderPlatformID ?? 1,
      senderNickname: m.senderNickname ?? '',
      senderFaceURL: m.senderFaceUrl ?? '',
      sessionType: m.sessionType ?? 1,
      contentType: ct,
      content: content,
      sendTime: m.sendTime ?? 0,
      createTime: m.createTime ?? 0,
      status: m.status ?? 1,
      seq: m.seq ?? 0,
      isRead: m.isRead ?? false,
    );
  }

  Map<String, dynamic> _pictureInfoToMap(sdk.PictureInfo? p) => {
        'url': p?.url ?? '',
        'width': p?.width ?? 0,
        'height': p?.height ?? 0,
        'type': p?.type ?? 'jpg',
        'size': 0,
      };

  // ─── 转换：SDK ConversationInfo → app Conversation ─────────────────

  Conversation _convertConversation(sdk.ConversationInfo c) {
    String latestMsgStr = '';
    if (c.latestMsg != null) {
      latestMsgStr = _msgPreview(c.latestMsg!);
    }
    return Conversation(
      conversationID: c.conversationID,
      conversationType: c.conversationType ?? 1,
      userID: c.userID ?? '',
      groupID: c.groupID ?? '',
      showName: c.showName ?? '',
      faceURL: c.faceURL ?? '',
      recvMsgOpt: c.recvMsgOpt ?? 0,
      unreadCount: c.unreadCount,
      latestMsg: latestMsgStr,
      latestMsgSendTime: c.latestMsgSendTime ?? 0,
      isPinned: c.isPinned ?? false,
    );
  }

  /// 从 SDK Message 提取会话列表预览文本
  String _msgPreview(sdk.Message m) {
    switch (m.contentType ?? 0) {
      case MessageContentType.text:
        return m.textElem?.content ?? '';
      case MessageContentType.atText:
        return m.atTextElem?.text ?? '[@消息]';
      case MessageContentType.image:
        return '[图片]';
      case MessageContentType.voice:
        return '[语音]';
      case MessageContentType.video:
        return '[视频]';
      case MessageContentType.file:
        return '[文件]';
      case MessageContentType.location:
        return '[位置]';
      case MessageContentType.quote:
        return m.quoteElem?.text ?? '[引用]';
      case MessageContentType.merge:
        return '[合并转发]';
      case MessageContentType.sticker:
      case MessageContentType.gif:
        return '[表情]';
      case MessageContentType.revoke:
        return '[已撤回]';
      default:
        if ((m.contentType ?? 0) >= 1000) return '[通知]';
        return '[消息]';
    }
  }

  // ─── 生命周期 ──────────────────────────────────────────────────────

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _msgSub?.cancel();
    _revokeSub?.cancel();
    _newMessageController.close();
    _revokedController.close();
  }
}
