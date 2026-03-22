import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';
import '../user_avatar.dart';

/// 联系人名片消息内容组件
class ContactMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ContactMessageContent(
      {super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // 联系人卡片从 custom content 中读取
    final data = message.content is Map
        ? (message.content as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final nickname =
        data['nickname'] as String? ?? data['name'] as String? ?? '联系人';
    final faceURL = data['faceURL'] as String? ?? '';
    final userID = data['userID'] as String? ?? '';

    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final subColor = isMe ? Colors.white70 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(faceURL: faceURL, nickname: nickname, size: 40),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nickname,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            if (userID.isNotEmpty)
              Text('ID: $userID',
                  style: TextStyle(fontSize: 12, color: subColor)),
          ],
        ),
      ],
    );
  }
}
