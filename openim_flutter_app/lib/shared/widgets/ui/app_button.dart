import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
}

/// 统一按钮组件
///
/// - [primary]：红色渐变填充（主操作，如登录/提交）
/// - [secondary]：丰收金填充（次要操作）
/// - [outline]：红色边框透明底（取消/次操作）
/// - [useGradient]：仅对 primary 生效，强制使用渐变背景（默认 true）
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool disabled;
  final bool useGradient;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.disabled = false,
    this.useGradient = true,
  });

  bool get _isDisabled => disabled || loading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.outline) {
      return SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                _isDisabled ? AppColors.disabled : AppColors.primary,
            side: BorderSide(
              color: _isDisabled ? AppColors.disabled : AppColors.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: _buildLabel(AppColors.primary),
        ),
      );
    }

    // ── primary / secondary ────────────────────────────────────────
    final isPrimary = variant == AppButtonVariant.primary;
    final useGrad = isPrimary && useGradient && !_isDisabled;

    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: useGrad
                ? const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: useGrad
                ? null
                : (_isDisabled
                    ? AppColors.disabled
                    : (isPrimary ? AppColors.primary : AppColors.accent)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isDisabled
                ? null
                : [
                    BoxShadow(
                      color: (isPrimary ? AppColors.primary : AppColors.accent)
                          .withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: _isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _buildLabel(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(Color color) {
    return Text(
      label,
      style: AppTypography.button.copyWith(color: color),
    );
  }
}
