import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 文本消息内容组件
class TextMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const TextMessageContent(
      {super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Text(
      message.textContent,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }
}
