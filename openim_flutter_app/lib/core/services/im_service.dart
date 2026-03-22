/// IM 消息服务抽象层 — 统一 SDK 和 HTTP 两种实现。
///
/// [ChatController] 和 [ConversationController] 通过此抽象调用消息能力，
/// 运行时根据 ConfigController.useSDK 选择 [SDKIMService] 或 [HTTPIMService]。
library;

import 'dart:async';
import '../models/message.dart';
import '../models/conversation.dart';

/// 发送消息结果
class SendResult {
  final bool success;
  final String? serverMsgID;
  final int? sendTime;
  final String? errorMsg;
  const SendResult({
    required this.success,
    this.serverMsgID,
    this.sendTime,
    this.errorMsg,
  });
}

/// 历史消息结果
class HistoryResult {
  final List<Message> messages;
  final bool isEnd;
  const HistoryResult({required this.messages, this.isEnd = false});
}

/// IM 服务统一接口
abstract class IMService {
  /// 服务实现名（用于日志）
  String get name;

  // ─── 消息收发 ──────────────────────────────────────────────────────

  /// 发送文本消息
  Future<SendResult> sendTextMessage({
    required String recvID,
    required String text,
    int sessionType = 1,
  });

  /// 发送图片消息
  Future<SendResult> sendImageMessage({
    required String recvID,
    required String imageUrl,
    int width = 0,
    int height = 0,
    int sessionType = 1,
  });

  /// 发送视频消息
  Future<SendResult> sendVideoMessage({
    required String recvID,
    required String videoUrl,
    String snapshotUrl = '',
    int duration = 0,
    int videoSize = 0,
    int sessionType = 1,
  });

  /// 发送文件消息
  Future<SendResult> sendFileMessage({
    required String recvID,
    required String fileUrl,
    required String fileName,
    int fileSize = 0,
    int sessionType = 1,
  });

  /// 发送语音消息
  Future<SendResult> sendVoiceMessage({
    required String recvID,
    required String voiceUrl,
    int duration = 0,
    int dataSize = 0,
    int sessionType = 1,
  });

  /// 通用发送（自定义 contentType + content）
  Future<SendResult> sendRawMessage({
    required String recvID,
    required int contentType,
    required dynamic content,
    int sessionType = 1,
  });

  // ─── 历史消息 ──────────────────────────────────────────────────────

  /// 拉取历史消息
  Future<HistoryResult> loadHistory({
    required String conversationID,
    int startSeq = 0,
    int endSeq = 0,
    int count = 40,
  });

  // ─── 已读状态 ──────────────────────────────────────────────────────

  /// 标记消息已读
  Future<void> markAsRead({
    required String conversationID,
    required List<int> seqs,
  });

  // ─── 会话列表 ──────────────────────────────────────────────────────

  /// 获取排序后的会话列表
  Future<List<Conversation>> getConversationList({int page = 1});

  // ─── 实时消息流 ────────────────────────────────────────────────────

  /// 新消息流（SDK 实现从 listener 推送，HTTP 实现从轮询注入）
  Stream<MapEntry<String, Message>> get onNewMessage;

  /// 消息撤回流 — 'revoke' + clientMsgID
  Stream<MapEntry<String, String>> get onMessageRevoked;

  /// 会话列表变更通知（SDK 同步完成 / 新增会话 / 会话变更时触发）
  Stream<void> get onConversationChanged;

  // ─── 生命周期 ──────────────────────────────────────────────────────

  /// 释放资源
  void dispose();
}
