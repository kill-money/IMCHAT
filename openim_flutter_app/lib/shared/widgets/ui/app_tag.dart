import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'app_text.dart';

enum AppTagType {
  green,
  orange,
}

/// 全局 Tag/徽章组件，圆角 20dp，14sp
class AppTag extends StatelessWidget {
  final String label;
  final AppTagType type;

  const AppTag({
    super.key,
    required this.label,
    this.type = AppTagType.green,
  });

  Color get _background {
    switch (type) {
      case AppTagType.orange:
        return AppColors.accent.withValues(alpha: 0.1);
      case AppTagType.green:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get _foreground {
    switch (type) {
      case AppTagType.orange:
        return AppColors.accent;
      case AppTagType.green:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        label,
        isSmall: true,
        style: TextStyle(
          color: _foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

