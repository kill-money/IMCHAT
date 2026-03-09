import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _areaCode = '+86';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final auth = context.read<AuthController>();
    final success = await auth.login(
      areaCode: _areaCode,
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
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
                  const Icon(
                    Icons.volunteer_activism,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppText(
                    '温暖行动 · 登录',
                    isTitle: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: '登 录',
                    onPressed: auth.loading ? null : _login,
                    loading: auth.loading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 显示登录失败的具体原因，方便在手机上直接看到
                  if (auth.error.isNotEmpty) ...[
                    AppText(
                      auth.error,
                      isSmall: true,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else
                    const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/register'),
                    child: const AppText(
                      '没有账号？立即注册',
                      isSmall: true,
                      style: TextStyle(color: AppColors.accent),
                    ),
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
