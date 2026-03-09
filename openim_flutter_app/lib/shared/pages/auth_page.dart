import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_feedback.dart';
import '../widgets/ui/app_text.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _loginPhoneCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNicknameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regInviteCtrl = TextEditingController();

  String _areaCode = '+86';
  bool _loginObscure = true;
  bool _regObscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (_tab.indexIsChanging) return;
    context.read<AuthController>().setError('');
    setState(() {});
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChange);
    _tab.dispose();
    _loginPhoneCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNicknameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    _regInviteCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    HapticFeedback.lightImpact();
    final phone = _loginPhoneCtrl.text.trim();
    final pass = _loginPassCtrl.text;
    final auth = context.read<AuthController>();
    if (phone.isEmpty || pass.isEmpty) {
      auth.setError('请填写手机号和密码');
      return;
    }
    final ok = await auth.login(
      areaCode: _areaCode,
      phoneNumber: phone,
      password: pass,
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pushReplacementNamed('/home');
  }

  void _register() async {
    HapticFeedback.lightImpact();
    final nickname = _regNicknameCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final pass = _regPassCtrl.text;
    final auth = context.read<AuthController>();
    if (nickname.isEmpty || phone.isEmpty || pass.isEmpty) {
      auth.setError('请填写昵称、手机号和密码');
      return;
    }
    final ok = await auth.register(
      nickname: nickname,
      areaCode: _areaCode,
      phoneNumber: phone,
      password: pass,
      invitationCode: _regInviteCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      AppFeedback.success(context, '注册成功，请登录');
      _regNicknameCtrl.clear();
      _regPhoneCtrl.clear();
      _regPassCtrl.clear();
      _regInviteCtrl.clear();
      auth.setError('');
      _tab.animateTo(0);
    }
  }

  Widget _areaDropdown() => SizedBox(
        width: 80,
        child: DropdownButtonFormField<String>(
          value: _areaCode,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: '+86', child: Text('+86')),
            DropdownMenuItem(value: '+1', child: Text('+1')),
          ],
          onChanged: (v) => setState(() => _areaCode = v!),
        ),
      );

  Widget _errorBanner(String error) {
    if (error.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppText(error,
              isSmall: true,
              style: const TextStyle(color: AppColors.danger)),
        ),
      ]),
    );
  }

  Widget _loginForm(AuthController auth) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _areaDropdown(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _loginPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: '手机号', prefixIcon: Icon(Icons.phone)),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _loginPassCtrl,
            obscureText: _loginObscure,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _loginObscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary),
                onPressed: () =>
                    setState(() => _loginObscure = !_loginObscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _errorBanner(auth.error),
          AppButton(
              label: '登 录',
              onPressed: auth.loading ? null : _login,
              loading: auth.loading),
        ],
      );

  Widget _registerForm(AuthController auth) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _regNicknameCtrl,
            decoration: const InputDecoration(
                labelText: '昵称', prefixIcon: Icon(Icons.person)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            _areaDropdown(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _regPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: '手机号', prefixIcon: Icon(Icons.phone)),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _regPassCtrl,
            obscureText: _regObscure,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _regObscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _regInviteCtrl,
            decoration: const InputDecoration(
                labelText: '邀请码（选填）',
                prefixIcon: Icon(Icons.card_giftcard)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _errorBanner(auth.error),
          AppButton(
              label: '注 册',
              onPressed: auth.loading ? null : _register,
              loading: auth.loading),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: isWide ? 400 : double.infinity,
            child: Column(children: [
              const Icon(Icons.volunteer_activism,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              const AppText('惠泽苍生',
                  isTitle: true, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              const AppText('精准扶贫 · 共同富裕',
                  isSmall: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                child: Column(children: [
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorWeight: 2,
                    dividerColor: Colors.transparent,
                    tabs: const [Tab(text: '登  录'), Tab(text: '注  册')],
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Consumer<AuthController>(
                      builder: (_, auth, __) => _tab.index == 0
                          ? _loginForm(auth)
                          : _registerForm(auth),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
