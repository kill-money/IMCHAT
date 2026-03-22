import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/status_controller.dart';
import '../../core/models/user_status.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_header.dart';
import '../widgets/ui/app_text.dart';

/// 隐私设置页 — 控制"上次在线时间"对外可见范围
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _saving = false;

  Future<void> _setPrivacy(LastSeenPrivacy privacy) async {
    setState(() => _saving = true);
    final ok = await context.read<StatusController>().setPrivacy(privacy);
    if (mounted) {
      setState(() => _saving = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<StatusController>().myPrivacy;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '隐私设置'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: const AppText(
                    '谁能看到我的"上次在线时间"',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                _privacyTile(
                    '所有人', '所有人均可看到', LastSeenPrivacy.everyone, current),
                const Divider(
                    height: 0.5,
                    indent: AppSpacing.lg,
                    color: AppColors.divider),
                _privacyTile(
                    '我的联系人', '仅好友可看到', LastSeenPrivacy.contacts, current),
                const Divider(
                    height: 0.5,
                    indent: AppSpacing.lg,
                    color: AppColors.divider),
                _privacyTile('不显示', '任何人均不可见', LastSeenPrivacy.nobody, current),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AppText(
              '选择"不显示"时，你也将无法看到其他用户的上次在线时间。',
              isSmall: true,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _privacyTile(
    String title,
    String subtitle,
    LastSeenPrivacy value,
    LastSeenPrivacy current,
  ) {
    final selected = current == value;
    return ListTile(
      title: AppText(title),
      subtitle: AppText(
        subtitle,
        isSmall: true,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.radio_button_unchecked,
              color: AppColors.textSecondary),
      onTap: _saving ? null : () => _setPrivacy(value),
    );
  }
}
