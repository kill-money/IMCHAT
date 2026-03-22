import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 引用/回复消息内容组件（上方引用条 + 下方回复文字）
class QuoteMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const QuoteMessageContent(
      {super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final quote = message.quoteContent;
    final text = quote?.text ?? '';
    final quoted = quote?.quoteMessage;

    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final quoteBackground =
        isMe ? Colors.white.withValues(alpha: 0.15) : AppColors.pageBackground;
    final quoteBorder = isMe ? Colors.white70 : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 引用气泡
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: quoteBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: quoteBorder, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quoted?.senderNickname.isNotEmpty == true)
                Text(
                  quoted!.senderNickname,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : AppColors.primary,
                  ),
                ),
              Text(
                quoted?.previewText ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: isMe
                        ? const Color(0xCCFFFFFF)
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 回复文字
        Text(
          text,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
