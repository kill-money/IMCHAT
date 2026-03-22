import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/ui/app_button.dart';
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
    HapticFeedback.lightImpact();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      context.read<AuthController>().setError('请填写手机号和密码');
      return;
    }
    final auth = context.read<AuthController>();
    final success = await auth.login(
      areaCode: _areaCode,
      phoneNumber: phone,
      password: password,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: isWide ? _buildWide(auth) : _buildNarrow(auth, screenHeight),
    );
  }

  Widget _buildWide(AuthController auth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl, horizontal: AppSpacing.xl),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _buildBrandBlock(),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildForm(auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow(AuthController auth, double screenHeight) {
    return Column(
      children: [
        Container(
          height: screenHeight * 0.38,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: -40, top: -40, child: _decorCircle(180, 0.06)),
              Positioned(
                  left: -30, bottom: -20, child: _decorCircle(130, 0.06)),
              Positioned(right: 60, bottom: 20, child: _decorCircle(60, 0.10)),
              SafeArea(child: Center(child: _buildBrandBlock())),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl),
            child: _buildForm(auth),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.volunteer_activism,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          '乡村振兴3.0',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '精准扶贫  ·  共同富裕',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildForm(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText(
          '账号登录',
          isTitle: true,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: DropdownButtonFormField<String>(
                value: _areaCode,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: '密码',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: auth.error.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppText(auth.error,
                            isSmall: true,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AppButton(
          label: '登  录',
          onPressed: auth.loading ? null : _login,
          loading: auth.loading,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/register'),
          child: const AppText(
            '没有账号？立即注册',
            isSmall: true,
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '主管单位：国家乡村振兴局',
          textAlign: TextAlign.center,
          style: AppTypography.caption
              .copyWith(color: AppColors.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026 乡村振兴3.0 · 精准扶贫信息服务平台',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
