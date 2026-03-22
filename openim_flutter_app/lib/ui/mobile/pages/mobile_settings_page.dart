import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/services/notification_sound_service.dart';
import '../../../core/utils/cache_utils.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_card_section.dart';
import '../../../shared/widgets/ui/app_list_tile.dart';
import '../../../shared/pages/device_manage_page.dart';

/// 设置页 — 账号安全 / 消息通知 / 通用 / 退出
class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  static const _kMsgSound = 'settings_msg_sound';
  static const _kMsgVibrate = 'settings_msg_vibrate';
  static const _kMsgPreview = 'settings_msg_preview';

  bool _msgSound = true;
  bool _msgVibrate = true;
  bool _msgPreview = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _msgSound = prefs.getBool(_kMsgSound) ?? true;
      _msgVibrate = prefs.getBool(_kMsgVibrate) ?? true;
      _msgPreview = prefs.getBool(_kMsgPreview) ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 功能开发中，敬请期待'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorText;
    final userID = context.read<AuthController>().currentUser?.userID ?? '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('修改密码'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '当前密码'),
                  validator: (v) => (v == null || v.isEmpty) ? '请输入当前密码' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '新密码'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入新密码';
                    if (v.length < 6) return '密码不少于 6 位';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '确认新密码'),
                  validator: (v) => v != newCtrl.text ? '两次密码不一致' : null,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(
                        () => errorText = null,
                      );
                      setDialogState(() => isLoading = true);
                      final result = await AuthApi.changePassword(
                        userID: userID,
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      setDialogState(() => isLoading = false);
                      final errCode = result['errCode'] as int? ?? -1;
                      if (errCode == 0) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('密码修改成功'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => errorText = '修改失败，请重试');
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认修改'),
            ),
          ],
        ),
      ),
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '退出',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AuthController>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '设置'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── 账号与安全 ────────────────────────────────
          AppCardSection(
            title: '账号与安全',
            children: [
              AppListTile(
                icon: Icons.lock_outline,
                iconColor: AppColors.primary,
                title: '修改密码',
                onTap: _showChangePasswordDialog,
              ),
              AppListTile(
                icon: Icons.shield_outlined,
                iconColor: AppColors.sky,
                title: '隐私设置',
                onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
              ),
              AppListTile(
                icon: Icons.devices_outlined,
                iconColor: AppColors.purple,
                title: '已登录设备',
                subtitle: '管理在其他设备的登录状态',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeviceManagePage()),
                ),
              ),
            ],
          ),

          // ── 消息通知 ──────────────────────────────────
          AppCardSection(
            title: '消息通知',
            children: [
              AppListTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.accent,
                title: '新消息提醒',
                showChevron: false,
                trailing: Switch(
                  value: _msgSound,
                  onChanged: (v) {
                    setState(() => _msgSound = v);
                    _saveBool(_kMsgSound, v);
                    NotificationSoundService.instance.enabled = v;
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              AppListTile(
                icon: Icons.vibration,
                iconColor: AppColors.success,
                title: '消息震动',
                showChevron: false,
                trailing: Switch(
                  value: _msgVibrate,
                  onChanged: (v) {
                    setState(() => _msgVibrate = v);
                    _saveBool(_kMsgVibrate, v);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              AppListTile(
                icon: Icons.remove_red_eye_outlined,
                iconColor: AppColors.activity,
                title: '通知预览',
                subtitle: '关闭后通知仅显示"您有一条新消息"',
                showChevron: false,
                trailing: Switch(
                  value: _msgPreview,
                  onChanged: (v) {
                    setState(() => _msgPreview = v);
                    _saveBool(_kMsgPreview, v);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),

          // ── 通用 ──────────────────────────────────────
          AppCardSection(
            title: '通用',
            children: [
              AppListTile(
                icon: Icons.language_outlined,
                iconColor: AppColors.teal,
                title: '语言',
                subtitle: '简体中文',
                onTap: () => _showComingSoon('语言切换'),
              ),
              AppListTile(
                icon: Icons.delete_outline,
                iconColor: AppColors.textSecondary,
                title: '清除缓存',
                subtitle: '释放本地存储空间',
                onTap: _clearCache,
              ),
            ],
          ),

          // ── 关于 ──────────────────────────────────────
          AppCardSection(
            title: '关于',
            children: [
              AppListTile(
                icon: Icons.info_outline,
                iconColor: AppColors.primary,
                title: '关于应用',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
            ],
          ),

          // ── 退出登录 ──────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final totalBytes = await clearAppCache();
      if (kIsWeb) {
        // Web 平台额外清理 SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await _loadPrefs(); // 重新加载默认值
      }
      final mb = (totalBytes / 1024 / 1024).toStringAsFixed(1);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(kIsWeb ? '缓存已清除' : '缓存已清除，释放 $mb MB'),
            duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('清除缓存异常: $e');
      messenger.showSnackBar(
        const SnackBar(
            content: Text('清除失败，请稍后重试'), duration: Duration(seconds: 2)),
      );
    }
  }
}
