import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'app_text.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool disabled;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.disabled = false,
  });

  bool get _isDisabled => disabled || loading || onPressed == null;

  Color get _backgroundColor {
    if (variant == AppButtonVariant.outline) return Colors.transparent;
    if (_isDisabled) return AppColors.disabled;
    if (variant == AppButtonVariant.secondary) return AppColors.accent;
    return AppColors.primary;
  }

  Color get _borderColor {
    if (variant == AppButtonVariant.outline) {
      return _isDisabled ? AppColors.disabled : AppColors.primary;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          disabledBackgroundColor: AppColors.disabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.cardBackground),
                ),
              )
            : AppText(
                label,
                style: const TextStyle(
                  color: AppColors.cardBackground,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}



