/// ImPollingService — 轻量级 HTTP 轮询，弥补原生 OpenIM WS SDK 缺失。
///
/// 原理：每 10 秒调用 /msg/get_conversations_has_read_and_max_seq，
/// 对比上次记录的 maxSeq；若有新消息，则：
///   1. 对当前打开的会话立即拉取新消息并注入 ChatController；
///   2. 刷新 ConversationController（更新未读数 & 最新消息预览）。
///
/// 本服务与 WebSocketService（Presence/10008）互补，
/// 共同构成完整的实时状态 + 消息更新体系。
library;

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;

import '../api/api_client.dart';
import '../api/chat_api.dart';
import '../controllers/chat_controller.dart';
import '../controllers/conversation_controller.dart';
import '../models/message.dart';

class ImPollingService {
  static final ImPollingService _instance = ImPollingService._();
  factory ImPollingService() => _instance;
  ImPollingService._();

  Timer? _pollTimer;
  bool _active = false;

  /// conversationID → 上次已知 maxSeq
  final Map<String, int> _lastMaxSeq = {};

  ConversationController? _convCtrl;
  ChatController? _chatCtrl;

  // ─── 公共 API ─────────────────────────────────────────────────────────────

  /// 登录后调用，启动周期轮询（间隔 10 秒）。
  void start({
    required ConversationController convCtrl,
    required ChatController chatCtrl,
  }) {
    _convCtrl = convCtrl;
    _chatCtrl = chatCtrl;
    _active = true;
    _lastMaxSeq.clear();
    _pollTimer?.cancel();
    // 立即执行一次，再开启周期
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  /// 登出时调用，停止轮询并清理状态。
  void stop() {
    _active = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastMaxSeq.clear();
    _convCtrl = null;
    _chatCtrl = null;
  }

  // ─── 内部逻辑 ─────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_active) return;
    final convCtrl = _convCtrl;
    final chatCtrl = _chatCtrl;
    if (convCtrl == null || chatCtrl == null) return;
    if (ApiConfig.userID.isEmpty || ApiConfig.imToken.isEmpty) return;

    try {
      final res = await MsgApi.getConversationsHasReadAndMaxSeq();
      final seqsRaw = res['data']?['seqs'] as Map<String, dynamic>?;
      if (seqsRaw == null || seqsRaw.isEmpty) {
        debugPrint('[IM_POLL] seq查询返回空');
        return;
      }

      bool hasNewMessages = false;
      int newCount = 0;

      for (final entry in seqsRaw.entries) {
        final convID = entry.key;
        final seqInfo = entry.value as Map<String, dynamic>? ?? {};
        final maxSeq = (seqInfo['maxSeq'] as num?)?.toInt() ?? 0;
        final lastKnown = _lastMaxSeq[convID];

        if (lastKnown == null) {
          // 首次记录：存档当前 seq。
          // 如果当前会话正在查看，也立即拉最近消息，防止首次遗漏。
          _lastMaxSeq[convID] = maxSeq;
          if (chatCtrl.currentConversationID == convID && maxSeq > 0) {
            final beginSeq = (maxSeq - 20).clamp(1, maxSeq);
            debugPrint(
                '[IM_POLL] 首次发现当前会话 $convID → 拉最近消息 seq $beginSeq→$maxSeq');
            await _fetchAndInject(chatCtrl, convID, beginSeq, maxSeq);
          }
          continue;
        }

        if (maxSeq > lastKnown) {
          _lastMaxSeq[convID] = maxSeq;
          hasNewMessages = true;
          newCount += maxSeq - lastKnown;

          // 若用户正在查看此会话，立即注入新消息
          if (chatCtrl.currentConversationID == convID) {
            debugPrint('[IM_POLL] 当前会话有 ${maxSeq - lastKnown} 条新消息 → 拉取');
            await _fetchAndInject(
              chatCtrl,
              convID,
              lastKnown + 1,
              maxSeq,
            );
          }
        }
      }

      // 任意会话有新消息 → 刷新会话列表（更新未读数 + latestMsg 预览）
      if (hasNewMessages) {
        debugPrint('[IM_POLL] 发现 $newCount 条新消息，刷新会话列表');
        await convCtrl.loadConversations();
      }
    } catch (e) {
      debugPrint('[IM_POLL] 轮询失败: $e');
    }
  }

  /// 拉取 [beginSeq, endSeq] 范围内的消息并注入 ChatController。
  Future<void> _fetchAndInject(
    ChatController chatCtrl,
    String conversationID,
    int beginSeq,
    int endSeq,
  ) async {
    try {
      final count = endSeq - beginSeq + 1;
      final res = await MsgApi.pullMsgBySeqs(seqRanges: [
        {
          'conversationID': conversationID,
          'begin': beginSeq,
          'end': endSeq,
          'num': count,
        }
      ]);
      final msgsData = res['data']?['msgs'] as Map<String, dynamic>? ?? {};
      final msgList = (msgsData[conversationID]?['msgs'] as List?) ?? [];
      debugPrint('[IM_POLL] 拉取到 ${msgList.length} 条消息 (seq $beginSeq→$endSeq)');
      for (final raw in msgList) {
        chatCtrl.addIncomingMessage(
          conversationID,
          Message.fromJson(raw as Map<String, dynamic>),
        );
      }
    } catch (e) {
      debugPrint('[IM_POLL] 拉取新消息失败 ($conversationID): $e');
    }
  }
}
