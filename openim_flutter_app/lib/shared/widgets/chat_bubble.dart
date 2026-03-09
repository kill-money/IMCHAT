import 'package:flutter/material.dart';
import '../platform_utils.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'ui/app_text.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final int contentType;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.contentType = 101,
    this.time = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * PlatformUtils.bubbleMaxWidthFactor,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (contentType == 102) {
      // Image message
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          text,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    // Text message
    return AppText(
      text,
      style: const TextStyle(
        color: AppColors.cardBackground,
      ),
    );
  }
}
