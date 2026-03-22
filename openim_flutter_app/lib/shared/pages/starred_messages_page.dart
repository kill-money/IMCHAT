import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/controllers/chat_controller.dart';
import '../../core/models/message.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/messages/message_bubble.dart';
import 'user_detail_page.dart';

/// 我的收藏（星标消息列表）
class StarredMessagesPage extends StatelessWidget {
  const StarredMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    // 从各会话中筛选出已收藏的消息
    final starred = chat.allMessages
        .where((m) => chat.isStarred(m.clientMsgID))
        .toList()
      ..sort((a, b) => b.sendTime.compareTo(a.sendTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          if (starred.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, chat),
              child:
                  const Text('清空', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: starred.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: AppSpacing.md),
                  Text('暂无收藏消息',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: starred.length,
              itemBuilder: (context, i) {
                final msg = starred[i];
                return _StarredItem(message: msg, chat: chat);
              },
            ),
    );
  }

  void _confirmClearAll(BuildContext context, ChatController chat) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确认清空所有收藏消息？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              chat.clearAllStarred();
            },
            child: const Text('清空', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _StarredItem extends StatelessWidget {
  final Message message;
  final ChatController chat;

  const _StarredItem({required this.message, required this.chat});

  @override
  Widget build(BuildContext context) {
    final isMe = message.sendID == ApiConfig.userID;
    final retrying = chat.isRetryingMsg(message.clientMsgID);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间戳 + 重试状态 + 取消收藏
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0),
          child: Row(
            children: [
              Text(
                _formatTime(message.sendTime),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (retrying) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => chat.forceRetry(message.clientMsgID),
                  child: Text(
                    '同步中(${chat.getRetryCount(message.clientMsgID)}) 点击重试',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.star, color: AppColors.accent, size: 20),
                tooltip: '取消收藏',
                onPressed: () => chat.unstarMessage(message.clientMsgID),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        MessageBubble(
          message: message,
          isMe: isMe,
          onAvatarTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => UserDetailPage(
                targetUserID: message.sendID,
                nickname: message.senderNickname,
                faceURL: message.senderFaceURL,
              ),
            ));
          },
        ),
        const Divider(height: 1, indent: AppSpacing.lg),
      ],
    );
  }

  String _formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
