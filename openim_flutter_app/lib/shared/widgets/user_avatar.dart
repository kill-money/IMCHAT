import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'ui/app_badge.dart';

class UserAvatar extends StatelessWidget {
  final String faceURL;
  final String nickname;
  final double size;
  final bool showBadge;
  final int badgeCount;
  /// 二开：用户端管理员角标（盾牌图标）
  final bool showAdminBadge;

  const UserAvatar({
    super.key,
    this.faceURL = '',
    this.nickname = '',
    this.size = 42,
    this.showBadge = false,
    this.badgeCount = 0,
    this.showAdminBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = faceURL.isNotEmpty
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(faceURL),
            backgroundColor: AppColors.divider,
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.primary,
            child: Text(
              nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.cardBackground,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

    final hasBadge = showBadge && badgeCount > 0;
    if (!hasBadge && !showAdminBadge) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (hasBadge)
          Positioned(
            right: -4,
            top: -4,
            child: AppBadge(count: badgeCount),
          ),
        if (showAdminBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.shield_outlined,
                size: size * 0.28,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
