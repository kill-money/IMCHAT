import 'package:flutter/material.dart';
import '../../core/models/conversation.dart';
import '../platform_utils.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'user_avatar.dart';
import 'ui/app_text.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback? onTap;

  const ConversationItem({
    super.key,
    required this.conversation,
    this.selected = false,
    this.onTap,
  });

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              UserAvatar(
                faceURL: conversation.faceURL,
                nickname: conversation.showName,
                size: PlatformUtils.avatarSize,
                showBadge: conversation.unreadCount > 0,
                badgeCount: conversation.unreadCount,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            conversation.showName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppText(
                          _formatTime(conversation.latestMsgSendTime),
                          isSmall: true,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      conversation.latestMsg,
                      isSmall: true,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
