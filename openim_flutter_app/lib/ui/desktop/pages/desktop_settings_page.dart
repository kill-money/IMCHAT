import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/api/user_api.dart'; // IP溯源
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../mobile/pages/mobile_wallet_page.dart'; // 钱包
import '../../../shared/pages/privacy_settings_page.dart'; // 隐私设置
import '../../mobile/pages/mobile_about_page.dart'; // 关于

/// Desktop settings panel — shown in the right area when sidebar = settings.
class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  String? _myIP;
  bool _ipLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    if (user != null && user.isAppAdmin) _loadMyIP(user.userID);
  }

  Future<void> _loadMyIP(String userID) async {
    setState(() => _ipLoading = true);
    try {
      final res = await UserApi.getUserIPInfo(targetUserID: userID);
      if ((res['errCode'] ?? 0) == 0) {
        final ip = (res['data'] as Map?)?['lastIP']?.toString() ?? '';
        setState(() => _myIP = ip.isEmpty ? '暂无记录' : ip);
      }
    } catch (e) {
      debugPrint('获取IP信息失败: $e');
    }
    setState(() => _ipLoading = false);
  }

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
            color: AppColors.bgCard,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
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
                  color: AppColors.bgCard,
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
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          // 仅管理员可见自己的 IP
                          if (user != null && user.isAppAdmin) ...[
                            const SizedBox(height: 2),
                            _ipLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5))
                                : Text(
                                    'IP: ${_myIP ?? '-'}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Settings items
              // 钱包入口（所有登录用户可见）
              _settingsTile(Icons.account_balance_wallet_outlined, '钱包', () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MobileWalletPage(),
                ));
              }),
              _settingsTile(Icons.notifications_outlined, '消息通知', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('消息通知设置即将上线'),
                      duration: Duration(seconds: 1)),
                );
              }),
              _settingsTile(Icons.lock_outline, '隐私设置', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsPage(),
                  ),
                );
              }),
              _settingsTile(Icons.palette_outlined, '主题', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('主题设置即将上线'),
                      duration: Duration(seconds: 1)),
                );
              }),
              _settingsTile(Icons.language, '语言', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('语言设置即将上线'),
                      duration: Duration(seconds: 1)),
                );
              }),
              _settingsTile(Icons.info_outline, '关于', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MobileAboutPage(),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.logout,
                      color: AppColors.danger, size: 18),
                  label: const Text('退出登录',
                      style: TextStyle(color: AppColors.danger)),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: AppColors.textPrimary),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing:
            Icon(Icons.chevron_right, size: 18, color: AppColors.disabled),
        onTap: onTap,
      ),
    );
  }
}
