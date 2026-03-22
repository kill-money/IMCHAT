import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/theme/colors.dart' show AppColors;

/// Web settings page — displayed as the main content panel when Settings tab is active.
class WebSettingsPage extends StatelessWidget {
  const WebSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            // Profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    UserAvatar(
                      faceURL: user?.faceURL ?? '',
                      nickname: user?.nickname ?? '',
                      size: 56,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? '未登录',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${user?.userID ?? ''}',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _settingsTile(Icons.notifications_outlined, '消息通知', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知设置功能开发中')),
              );
            }),
            _settingsTile(Icons.lock_outline, '隐私设置', () {
              Navigator.of(context).pushNamed('/privacy-settings');
            }),
            _settingsTile(Icons.palette_outlined, '主题', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题设置功能开发中')),
              );
            }),
            _settingsTile(Icons.language, '语言', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('语言设置功能开发中')),
              );
            }),
            _settingsTile(Icons.info_outline, '关于', () {
              Navigator.of(context).pushNamed('/about');
            }),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: Icon(Icons.logout, color: AppColors.danger, size: 18),
                label: const Text('退出登录',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: Icon(icon, size: 22, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing:
            Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
