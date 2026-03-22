import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'app_text.dart';

enum AppTagType {
  primary,
  orange,
}

/// 全局 Tag/徽章组件，圆角 20dp，14sp
class AppTag extends StatelessWidget {
  final String label;
  final AppTagType type;

  const AppTag({
    super.key,
    required this.label,
    this.type = AppTagType.primary,
  });

  Color get _background {
    switch (type) {
      case AppTagType.orange:
        return AppColors.accent.withValues(alpha: 0.1);
      case AppTagType.primary:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get _foreground {
    switch (type) {
      case AppTagType.orange:
        return AppColors.accent;
      case AppTagType.primary:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
          color: AppColors.contrastSafe(_foreground, brightness),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
