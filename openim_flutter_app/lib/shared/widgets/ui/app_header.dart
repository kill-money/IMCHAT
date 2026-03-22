import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'app_text.dart';

/// 全局页头组件，统一高度 56dp、背景与阴影
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final Widget? right;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.right,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (showBack)
                      InkWell(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: AppText(
                      title,
                      isTitle: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.appBar,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
