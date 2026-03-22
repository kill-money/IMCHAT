import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../user_avatar.dart';
import 'text_message_content.dart';
import 'image_message_content.dart';
import 'video_message_content.dart';
import 'voice_message_content.dart';
import 'file_message_content.dart';
import 'location_message_content.dart';
import 'contact_message_content.dart';
import 'quote_message_content.dart';
import 'sticker_message_content.dart';
import 'merge_message_content.dart';

/// 统一消息气泡组件 — 根据 contentType 分发到对应内容组件。
/// 用于替换旧版 ChatBubble，支持：
///  - 全部 OpenIM 消息类型（含 sticker/GIF）
///  - 发送者头像 + 昵称（群聊模式）
///  - 时间戳 + 已读回执（✓ 已送达 / ✓✓ 已读）
///  - Reaction 表情条（传入 reactions 列表）
///  - 选中高亮（多选模式）
///  - 长按回调
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  /// 是否在多选模式下被选中
  final bool isSelected;

  /// 群聊时显示发送者昵称
  final bool showSenderName;

  /// 该消息收到的 reactions，格式：{emoji: [senderID, ...]}
  final Map<String, List<String>> reactions;

  /// 点击某个 reaction 时触发（传入 emoji）
  final ValueChanged<String>? onReactionTap;

  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  /// 点击头像回调（跳转用户资料页）
  final VoidCallback? onAvatarTap;

  /// 当前会话中所有图片URL列表（用于画廊浏览）
  final List<String> allImageUrls;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isSelected = false,
    this.showSenderName = false,
    this.reactions = const {},
    this.onReactionTap,
    this.onLongPress,
    this.onTap,
    this.onAvatarTap,
    this.allImageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _buildRow(maxWidth),
        ),
      ),
    );
  }

  List<Widget> _buildRow(double maxWidth) {
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && showSenderName)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderNickname,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),
          _buildBubbleContent(),
          const SizedBox(height: 2),
          _buildTimestampRow(),
          // Reaction chips below timestamp
          if (reactions.isNotEmpty) _buildReactionBar(),
        ],
      ),
    );

    final avatar = GestureDetector(
      onTap: onAvatarTap,
      child: UserAvatar(
        faceURL: message.senderFaceURL,
        nickname: message.senderNickname,
        size: 30,
      ),
    );

    if (isMe) {
      return [bubble, const SizedBox(width: 6), avatar];
    } else {
      return [avatar, const SizedBox(width: 6), bubble];
    }
  }

  Widget _buildTimestampRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.sendTime),
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          const Text(
            '已编辑',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
        if (isMe) ...[
          const SizedBox(width: 3),
          // 已读回执：发送中=⏱  已送达=✓  已读=✓✓(蓝色)
          if (message.status == 1)
            const Icon(Icons.schedule, size: 11, color: AppColors.textSecondary)
          else if (message.isRead)
            const Icon(Icons.done_all, size: 11, color: AppColors.primary)
          else
            const Icon(Icons.done, size: 11, color: AppColors.textSecondary),
        ],
      ],
    );
  }

  /// 显示 reaction 表情条
  Widget _buildReactionBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: reactions.entries.map((e) {
          final emoji = e.key;
          final count = e.value.length;
          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '$emoji $count',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 实际气泡背景 + 内容
  Widget _buildBubbleContent() {
    // 撤回消息：无气泡，纯文字提示
    if (message.isRevoke) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '消息已被撤回',
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic),
        ),
      );
    }

    final content = _buildContent();

    // 图片 / 视频：无内边距，圆角裁剪
    if (message.isImage || message.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    // 其他类型：标准气泡容器
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: content,
    );
  }

  /// 根据 contentType 分发内容组件
  Widget _buildContent() {
    switch (message.contentType) {
      case MessageContentType.text:
        return TextMessageContent(message: message, isMe: isMe);
      case MessageContentType.image:
        final thisUrl = message.imageContent?.url ?? '';
        final idx = allImageUrls.indexOf(thisUrl);
        return ImageMessageContent(
          message: message,
          allImageUrls: allImageUrls,
          currentIndex: idx >= 0 ? idx : 0,
        );
      case MessageContentType.video:
        return VideoMessageContent(message: message);
      case MessageContentType.voice:
        return VoiceMessageContent(message: message, isMe: isMe);
      case MessageContentType.file:
        return FileMessageContent(message: message, isMe: isMe);
      case MessageContentType.location:
        return LocationMessageContent(message: message, isMe: isMe);
      case MessageContentType.quote:
        return QuoteMessageContent(message: message, isMe: isMe);
      case MessageContentType.custom:
        return ContactMessageContent(message: message, isMe: isMe);
      case MessageContentType.merge:
        return MergeMessageContent(message: message, isMe: isMe);
      case MessageContentType.sticker:
      case MessageContentType.gif:
        return StickerMessageContent(message: message);
      default:
        return Text(
          '[暂不支持该消息类型]',
          style: TextStyle(
              fontSize: 13,
              color: isMe ? const Color(0xCCFFFFFF) : AppColors.textSecondary,
              fontStyle: FontStyle.italic),
        );
    }
  }

  String _formatTime(int ms) {
    if (ms == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
