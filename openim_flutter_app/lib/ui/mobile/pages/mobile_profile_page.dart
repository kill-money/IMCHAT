import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/ui/app_button.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';

class MobileProfilePage extends StatelessWidget {
  const MobileProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(
        title: '我的',
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                UserAvatar(
                  faceURL: user?.faceURL ?? '',
                  nickname: user?.nickname ?? '',
                  size: 60,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        user?.nickname ?? '未登录',
                        isTitle: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        'ID: ${user?.userID ?? ''}',
                        isSmall: true,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildItem(Icons.settings, '设置', () {}),
          _buildItem(Icons.info_outline, '关于', () {}),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: '退出登录',
            variant: AppButtonVariant.outline,
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.cardBackground,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

