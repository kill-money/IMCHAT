import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/pages/legal_content_page.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_card_section.dart';
import '../../../shared/widgets/ui/app_list_tile.dart';

/// 关于应用页
class MobileAboutPage extends StatefulWidget {
  const MobileAboutPage({super.key});

  @override
  State<MobileAboutPage> createState() => _MobileAboutPageState();
}

class _MobileAboutPageState extends State<MobileAboutPage> {
  static const _version = '1.0.0';
  static const _buildNumber = '20260308';
  bool _checking = false;

  void _openLegalPage(String title, String configKey) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LegalContentPage(title: title, configKey: configKey),
    ));
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'windows');
      final resp = await ChatApi.post(
        '/application/latest_version',
        {'platform': platform},
      );
      if (!mounted) return;
      final data = resp['data'] as Map<String, dynamic>?;
      final latestVersion = data?['version'] as String? ?? _version;
      final downloadUrl = data?['downloadUrl'] as String? ?? '';

      if (_compareVersions(latestVersion, _version) > 0) {
        _showUpdateDialog(latestVersion, downloadUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前已是最新版本'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检查更新失败，请稍后再试'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// 语义版本号比较: 返回正数表示 a > b
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }

  void _showUpdateDialog(String version, String downloadUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发现新版本'),
        content: Text('最新版本: $version\n当前版本: $_version'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后再说'),
          ),
          if (downloadUrl.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('前往更新'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '关于应用'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── App 标识卡片 ──────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.volunteer_activism,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '乡村振兴3.0',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  '精准扶贫 · 共同富裕',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '版本 $_version（Build $_buildNumber）',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── 法律条款 ──────────────────────────────────
          AppCardSection(
            title: '法律与隐私',
            children: [
              AppListTile(
                icon: Icons.article_outlined,
                iconColor: AppColors.primary,
                title: '用户服务协议',
                onTap: () => _openLegalPage('用户服务协议', 'terms_of_service'),
              ),
              AppListTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.sky,
                title: '隐私政策',
                onTap: () => _openLegalPage('隐私政策', 'privacy_policy'),
              ),
            ],
          ),

          // ── 更新 ──────────────────────────────────────
          AppCardSection(
            title: '版本',
            children: [
              AppListTile(
                icon: Icons.system_update_outlined,
                iconColor: AppColors.success,
                title: '检查更新',
                subtitle: _checking ? '正在检查…' : '当前版本 $_version',
                onTap: _checkUpdate,
              ),
            ],
          ),

          // ── 版权 ──────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          Text(
            '© 2026 乡村振兴3.0团队 保留所有权利\n本软件基于 OpenIM 开源项目构建',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
