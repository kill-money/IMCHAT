import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Desktop settings panel — shown in the right area when sidebar = settings.
class DesktopSettingsPage extends StatelessWidget {
  const DesktopSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Column(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          alignment: Alignment.centerLeft,
          child: const Text('设置',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      faceURL: user?.faceURL ?? '',
                      nickname: user?.nickname ?? '',
                      size: 50,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? '未登录',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${user?.userID ?? ''}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Settings items
              _settingsTile(Icons.notifications_outlined, '消息通知', () {}),
              _settingsTile(Icons.lock_outline, '隐私设置', () {}),
              _settingsTile(Icons.palette_outlined, '主题', () {}),
              _settingsTile(Icons.language, '语言', () {}),
              _settingsTile(Icons.info_outline, '关于', () {}),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text('退出登录',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing:
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
