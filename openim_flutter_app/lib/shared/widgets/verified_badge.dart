import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 官方账号认证徽章
/// - [color] 默认蓝色（管理员/角色标识），官方账号传 [AppColors.gold] 显示金色
class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color color;

  const VerifiedBadge({
    super.key,
    this.size = 15,
    this.color = AppColors.sky,
  });

  /// 金色官方账号徽章
  const VerifiedBadge.gold({super.key, this.size = 15})
      : color = const Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Icon(Icons.verified, color: color, size: size),
    );
  }
}

/// 带可选认证徽章的昵称行
/// - [isOfficial] >= 1 显示金色金 V 徽章（官方账号）
/// - [appRole]   >= 1 显示蓝色认证徽章（管理员/角色）
class UserNameWithBadge extends StatelessWidget {
  final String nickname;
  final int appRole;
  final int isOfficial;
  final TextStyle? style;
  final double badgeSize;

  const UserNameWithBadge({
    super.key,
    required this.nickname,
    this.appRole = 0,
    this.isOfficial = 0,
    this.style,
    this.badgeSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            nickname,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOfficial >= 1)
          VerifiedBadge.gold(size: badgeSize)
        else if (appRole >= 1)
          VerifiedBadge(size: badgeSize),
      ],
    );
  }
}

/// 带可选官方群徽章的群名称行
class GroupNameWithBadge extends StatelessWidget {
  final String name;
  final bool isOfficialGroup;
  final TextStyle? style;
  final double badgeSize;

  const GroupNameWithBadge({
    super.key,
    required this.name,
    this.isOfficialGroup = false,
    this.style,
    this.badgeSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOfficialGroup) VerifiedBadge.gold(size: badgeSize),
      ],
    );
  }
}
