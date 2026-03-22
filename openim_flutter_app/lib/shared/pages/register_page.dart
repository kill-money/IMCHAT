import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_feedback.dart';
import '../widgets/ui/app_text.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  String _areaCode = '+86';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _register() async {
    HapticFeedback.lightImpact();

    final nickname = _nicknameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (nickname.isEmpty || phone.isEmpty || password.isEmpty) {
      context.read<AuthController>().setError('请填写昵称、手机号和密码');
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.register(
      nickname: nickname,
      areaCode: _areaCode,
      phoneNumber: phone,
      password: password,
      invitationCode: _inviteCodeController.text.trim(),
      downloadReferrer: ApiConfig.downloadReferrer, // 推荐人 ID
    );
    if (!mounted) return;
    if (success) {
      final receptionistID = auth.lastReceptionistID;
      final msg = receptionistID.isNotEmpty ? '注册成功，已绑定您的专属接待员' : '注册成功，请登录';
      AppFeedback.success(context, msg);
      Navigator.of(context).pop();
    }
    // 失败时 auth.error 已更新，inline 区域自动展示
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const AppText('注册账号', isTitle: true),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: isWide ? 400 : double.infinity,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<String>(
                          value: _areaCode,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: '+86', child: AppText('+86')),
                            DropdownMenuItem(value: '+1', child: AppText('+1')),
                          ],
                          onChanged: (v) => setState(() => _areaCode = v!),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: '手机号',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: '邀请码（选填）',
                      prefixIcon: Icon(Icons.card_giftcard),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // ── 统一内联错误区 ────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: auth.error.isNotEmpty
                        ? Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.danger, size: 16),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: AppText(
                                    auth.error,
                                    isSmall: true,
                                    style: const TextStyle(
                                        color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AppButton(
                    label: '注 册',
                    onPressed: auth.loading ? null : _register,
                    loading: auth.loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
