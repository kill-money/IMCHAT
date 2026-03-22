import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/config_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] SplashPage');
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // 最少展示 1.5 秒 Splash 画面，同时尝试恢复 Session
    final auth = context.read<AuthController>();
    final results = await Future.wait([
      auth.tryRestoreSession(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;
    final restored = results.first as bool;
    if (restored) {
      // 登录恢复成功，加载远端配置再进入主界面
      await context.read<ConfigController>().load();
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, restored ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/web/web_splash_launch_desktop_v1.0.0.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
