import 'package:flutter/material.dart';
import '../../core/models/conversation.dart';
import '../../core/models/user_status.dart';
import '../platform_utils.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'user_avatar.dart';
import 'ui/app_text.dart';
import 'verified_badge.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 仅单聊（conversationType==1）时传入，用于显示在线状态
  final UserStatus? userStatus;

  const ConversationItem({
    super.key,
    required this.conversation,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.userStatus,
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

  /// 副标题：单聊时优先展示在线状态文字，其次展示最后一条消息
  String _subtitle() {
    if (conversation.conversationType == 1 && userStatus != null) {
      return userStatus!.lastSeenText;
    }
    return conversation.latestMsg;
  }

  /// 副标题颜色：在线时使用绿色强调
  Color _subtitleColor() {
    if (conversation.conversationType == 1 && (userStatus?.isOnline ?? false)) {
      return AppColors.success;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        conversation.conversationType == 1 && (userStatus?.isOnline ?? false);

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                isOnline: isOnline,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 置顶图标
                        if (conversation.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 13, color: AppColors.accent),
                          ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: AppText(
                                  conversation.showName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.isOfficialUser >= 1 ||
                                  conversation.isOfficialGroup)
                                const VerifiedBadge.gold()
                              else if (conversation.appRole >= 1)
                                const VerifiedBadge(),
                            ],
                          ),
                        ),
                        // 静音图标
                        if (conversation.isMuted)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.volume_off_outlined,
                                size: 13, color: AppColors.textSecondary),
                          ),
                        AppText(
                          _formatTime(conversation.latestMsgSendTime),
                          isSmall: true,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      _subtitle(),
                      isSmall: true,
                      style: TextStyle(color: _subtitleColor()),
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
