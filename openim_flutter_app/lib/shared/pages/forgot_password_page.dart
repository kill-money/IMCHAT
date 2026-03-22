import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/auth_api.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_text.dart';

/// 忘记密码页（三步流程）
/// 步骤 1：输入手机号 → 发送验证码
/// 步骤 2：输入验证码 → 校验
/// 步骤 3：设置新密码 → 完成重置
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 0; // 0=手机号, 1=验证码, 2=新密码

  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _newPassObscure = true;
  bool _confirmPassObscure = true;
  String _error = '';

  final String _areaCode = '+86';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _setError(String msg) => setState(() => _error = msg);
  void _setLoading(bool v) => setState(() {
        _loading = v;
        if (v) _error = '';
      });

  // ── 步骤 1：发送验证码 ─────────────────────────────────────────────
  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _setError('请输入手机号');
      return;
    }
    HapticFeedback.lightImpact();
    _setLoading(true);

    try {
      final res = await AuthApi.sendVerifyCode(
        usedFor: 2, // 2 = 找回密码
        areaCode: _areaCode,
        phoneNumber: phone,
      );
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _setError(res['errMsg']?.toString() ?? '发送失败，请稍后重试');
      } else {
        setState(() {
          _step = 1;
          _error = '';
        });
      }
    } catch (_) {
      _setError('网络错误，请检查连接后重试');
    } finally {
      _setLoading(false);
    }
  }

  // ── 步骤 2：校验验证码 ─────────────────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) {
      _setError('请输入验证码');
      return;
    }
    HapticFeedback.lightImpact();
    _setLoading(true);

    try {
      final res = await AuthApi.verifyCode(
        areaCode: _areaCode,
        phoneNumber: _phoneCtrl.text.trim(),
        verifyCode: code,
      );
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _setError(res['errMsg']?.toString() ?? '验证码错误');
      } else {
        setState(() {
          _step = 2;
          _error = '';
        });
      }
    } catch (_) {
      _setError('网络错误，请检查连接后重试');
    } finally {
      _setLoading(false);
    }
  }

  // ── 步骤 3：重置密码 ───────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (newPass.length < 6) {
      _setError('密码至少6位');
      return;
    }
    if (newPass != confirm) {
      _setError('两次密码不一致');
      return;
    }
    HapticFeedback.lightImpact();
    _setLoading(true);

    try {
      final res = await AuthApi.resetPassword(
        areaCode: _areaCode,
        phoneNumber: _phoneCtrl.text.trim(),
        verifyCode: _codeCtrl.text.trim(),
        newPassword: newPass,
      );
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _setError(res['errMsg']?.toString() ?? '重置失败，请重试');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码重置成功，请登录')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      _setError('网络错误，请检查连接后重试');
    } finally {
      _setLoading(false);
    }
  }

  // ── UI 组件 ────────────────────────────────────────────────────────

  Widget _errorBanner() {
    if (_error.isEmpty) return const SizedBox.shrink();
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
          child: Text(
            _error,
            style: const TextStyle(fontSize: 13, color: AppColors.danger),
          ),
        ),
      ]),
    );
  }

  Widget _stepIndicator() {
    const total = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= _step;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  // 步骤 1：手机号
  Widget _buildStep0() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText('找回密码', isTitle: true, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '请输入注册时的手机号，我们将向其发送验证码',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            Container(
              width: 52,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('+86',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                onSubmitted: (_) => _loading ? null : _sendCode(),
                decoration: const InputDecoration(
                    labelText: '手机号', prefixIcon: Icon(Icons.phone)),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _errorBanner(),
          AppButton(
            label: '获取验证码',
            onPressed: _loading ? null : _sendCode,
            loading: _loading,
          ),
        ],
      );

  // 步骤 2：验证码
  Widget _buildStep1() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText('输入验证码', isTitle: true, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '验证码已发送至 $_areaCode ${_phoneCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onSubmitted: (_) => _loading ? null : _verifyCode(),
            decoration: const InputDecoration(
              labelText: '验证码',
              prefixIcon: Icon(Icons.pin),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _sendCode,
              child: const Text('重新发送',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _errorBanner(),
          AppButton(
            label: '验 证',
            onPressed: _loading ? null : _verifyCode,
            loading: _loading,
          ),
        ],
      );

  // 步骤 3：新密码
  Widget _buildStep2() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText('设置新密码', isTitle: true, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '请设置您的新密码（至少6位）',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _newPassCtrl,
            obscureText: _newPassObscure,
            decoration: InputDecoration(
              labelText: '新密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPassObscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _newPassObscure = !_newPassObscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: _confirmPassObscure,
            onSubmitted: (_) => _loading ? null : _resetPassword(),
            decoration: InputDecoration(
              labelText: '确认密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPassObscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _confirmPassObscure = !_confirmPassObscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _errorBanner(),
          AppButton(
            label: '重置密码',
            onPressed: _loading ? null : _resetPassword,
            loading: _loading,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('找回密码'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: isWide ? 400 : double.infinity,
            child: Column(children: [
              const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              _stepIndicator(),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                margin: EdgeInsets.zero,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _buildStep0(),
                      1 => _buildStep1(),
                      _ => _buildStep2(),
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
