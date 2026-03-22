import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'ui/app_badge.dart';

class UserAvatar extends StatelessWidget {
  final String faceURL;
  final String nickname;
  final double size;
  final bool showBadge;
  final int badgeCount;

  /// 用户端管理员角标（盾牌图标）
  final bool showAdminBadge;

  /// 在线状态绿点（spec: 10px, #4CAF50, 右下角）
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.faceURL = '',
    this.nickname = '',
    this.size = 42,
    this.showBadge = false,
    this.badgeCount = 0,
    this.showAdminBadge = false,
    this.isOnline = false,
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
    if (!hasBadge && !showAdminBadge && !isOnline) return avatar;

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
        // 在线绿点 — AnimatedOpacity 避免 UI 闪烁，isOnline 变化时平滑淡入/出
        Positioned(
          right: -1,
          bottom: -1,
          child: AnimatedOpacity(
            opacity: isOnline ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBackground,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        if (!isOnline && showAdminBadge)
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
