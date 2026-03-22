import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// 统一列表行组件 — 用于设置页、个人资料菜单等
///
/// 用法：
/// ```dart
/// AppListTile(
///   icon: Icons.lock_outline,
///   iconColor: AppColors.primary,
///   title: '修改密码',
///   subtitle: '定期修改以保障账号安全',
///   onTap: () => Navigator.pushNamed(context, '/change-password'),
/// )
/// ```
class AppListTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String title;
  final String? subtitle;

  /// 自定义尾部 widget（不传时根据 [showChevron] 决定）
  final Widget? trailing;

  /// 是否在尾部显示 ›（默认 true）
  final bool showChevron;

  final VoidCallback? onTap;

  /// 紧凑模式 — 减少垂直 padding（用于数据密度高的列表）
  final bool dense;

  const AppListTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackground,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveBg =
        iconBackground ?? effectiveIconColor.withValues(alpha: 0.12);

    Widget? leadingWidget;
    if (icon != null) {
      leadingWidget = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: effectiveIconColor),
      );
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && showChevron) {
      trailingWidget = const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textSecondary,
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: dense ? 0 : AppSpacing.xs,
      ),
      leading: leadingWidget,
      title: Text(title, style: AppTypography.body),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.small,
            )
          : null,
      trailing: trailingWidget,
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.06),
      shape: const RoundedRectangleBorder(),
    );
  }
}
