import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
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

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _register() async {
    final auth = context.read<AuthController>();
    final success = await auth.register(
      nickname: _nicknameController.text.trim(),
      areaCode: _areaCode,
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      invitationCode: _inviteCodeController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，请登录')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: const AppText(
          '注册',
          isTitle: true,
        ),
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
                children: [
                  const AppText(
                    '创建账号',
                    isTitle: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      border: OutlineInputBorder(),
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
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.md,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: '+86', child: AppText('+86')),
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
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: '邀请码 (选填)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.card_giftcard),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
