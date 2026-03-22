import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/api/user_api.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/ui/app_button.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';
import 'mobile_wallet_page.dart';
import '../../../shared/pages/profile_edit_page.dart';
import '../../../shared/pages/starred_messages_page.dart';

class MobileProfilePage extends StatefulWidget {
  const MobileProfilePage({super.key});

  @override
  State<MobileProfilePage> createState() => _MobileProfilePageState();
}

class _MobileProfilePageState extends State<MobileProfilePage> {
  String? _myIP;
  bool _ipLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    // 每次进入"我的"页面时从服务端刷新最新资料
    auth.refreshUserInfo();
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
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
              );
              if (changed == true) {
                context.read<AuthController>().refreshUserInfo();
              }
            },
            child: Row(
              children: [
                UserAvatar(
                  faceURL: user?.faceURL ?? '',
                  nickname: user?.nickname ?? '',
                  size: 60,
                  showAdminBadge: user?.isAppAdmin ?? false,
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
                      // 个性签名
                      if (user != null && user.signature.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AppText(
                          user.signature,
                          isSmall: true,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                      // 仅管理员可见自己的 IP，普通用户不渲染
                      if (user != null && user.isAppAdmin) ...[
                        const SizedBox(height: 2),
                        _ipLoading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 1.5))
                            : AppText(
                                'IP: ${_myIP ?? '-'}',
                                isSmall: true,
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                      ],
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
          _buildItem(Icons.account_balance_wallet_outlined, '钱包', () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MobileWalletPage(),
            ));
          }),
          _buildItem(Icons.star_outline, '我的收藏', () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const StarredMessagesPage(),
            ));
          }),
          _buildItem(Icons.settings, '设置', () {
            Navigator.of(context).pushNamed('/settings');
          }),
          _buildItem(Icons.info_outline, '关于', () {
            Navigator.of(context).pushNamed('/about');
          }),
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
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
