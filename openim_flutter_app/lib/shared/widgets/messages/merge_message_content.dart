import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 合并转发消息气泡内容 — 显示标题 + 摘要行
class MergeMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MergeMessageContent({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final merge = message.mergeContent;
    final title = merge?.title ?? '聊天记录';
    final abstracts = merge?.abstractList ?? [];
    final count = merge?.multiMessage.length ?? 0;

    return GestureDetector(
      onTap: () => _showDetail(context, merge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.library_books_outlined,
                  size: 16, color: isMe ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 摘要行（最多 4 条）
          ...abstracts.take(4).map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe
                        ? const Color(0xCCFFFFFF)
                        : AppColors.textSecondary,
                  ),
                ),
              )),
          Divider(height: 12, color: isMe ? Colors.white38 : AppColors.divider),
          Text(
            '共 $count 条消息',
            style: TextStyle(
              fontSize: 11,
              color: isMe ? const Color(0xCCFFFFFF) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, MergeContent? merge) {
    if (merge == null || merge.multiMessage.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MergeDetailPage(merge: merge),
    ));
  }
}

/// 合并转发详情页 — 展开显示全部被合并的消息
class _MergeDetailPage extends StatelessWidget {
  final MergeContent merge;

  const _MergeDetailPage({required this.merge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(merge.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: merge.multiMessage.length,
        itemBuilder: (_, i) {
          final msg = merge.multiMessage[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    msg.senderNickname.isNotEmpty ? msg.senderNickname[0] : '?',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.senderNickname,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.previewText,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
