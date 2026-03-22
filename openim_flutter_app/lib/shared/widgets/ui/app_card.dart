import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// 卡片外观变体
enum AppCardVariant {
  /// 默认：白底 + 投影
  elevated,

  /// 无投影白底（嵌套布局用）
  flat,

  /// 轮廓描边，无投影
  outlined,
}

/// 全局卡片组件，统一圆角、阴影与内边距
///
/// 用法示例：
/// ```dart
/// // 基础卡片
/// AppCard(child: Text('内容'))
///
/// // 描边变体
/// AppCard(variant: AppCardVariant.outlined, child: ...)
///
/// // 渐变卡片（带 gradient 参数）
/// AppCard(gradient: LinearGradient(...), child: ...)
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  /// 当传入渐变时忽略 [backgroundColor] 与 [variant] 背景色
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = AppCardVariant.elevated,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.gradient,
  });

  BoxDecoration _decoration() {
    final radius = BorderRadius.circular(borderRadius);
    switch (variant) {
      case AppCardVariant.flat:
        return BoxDecoration(
          color: gradient != null
              ? null
              : (backgroundColor ?? AppColors.cardBackground),
          gradient: gradient,
          borderRadius: radius,
        );
      case AppCardVariant.outlined:
        return BoxDecoration(
          color: gradient != null
              ? null
              : (backgroundColor ?? AppColors.cardBackground),
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(
            color: borderColor ?? AppColors.divider,
            width: 1,
          ),
        );
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: gradient != null
              ? null
              : (backgroundColor ?? AppColors.cardBackground),
          gradient: gradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
      decoration: _decoration(),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}
