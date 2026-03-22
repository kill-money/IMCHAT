import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// iOS 风格的分组设置卡片（section title + 圆角卡片 + 分割线）
///
/// 用法：
/// ```dart
/// AppCardSection(
///   title: '账号与安全',
///   children: [
///     AppListTile(icon: Icons.lock, title: '修改密码', onTap: () {}),
///     AppListTile(icon: Icons.shield, title: '隐私设置', onTap: () {}),
///   ],
/// )
/// ```
class AppCardSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const AppCardSection({
    super.key,
    this.title,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: _withDividers(children),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(
          const Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 56,
            endIndent: 0,
            color: AppColors.divider,
          ),
        );
      }
    }
    return result;
  }
}
