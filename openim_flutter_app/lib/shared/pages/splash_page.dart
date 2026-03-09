import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 资产映射：各平台启动图路径（对应 asset_map.json splash_launch 条目）
class _SplashAssets {
  static const android =
      'assets/images/mobile/android/android_splash_launch_xxhdpi_v1.0.0.jpg';
  static const ios =
      'assets/images/mobile/ios/ios_splash_launch_@3x_v1.0.0.jpg';

  static String get current {
    if (!kIsWeb && Platform.isAndroid) return android;
    if (!kIsWeb && Platform.isIOS) return ios;
    return android; // fallback（不应被调用，见 SplashPage.build）
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    // 桌面端 / Web端：跳过启动图，直接进入登录
    final delay = _isMobile ? const Duration(seconds: 3) : Duration.zero;
    Future.delayed(delay, () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 非移动端：透明占位，等待 initState 的即时跳转
    if (!_isMobile) {
      return const Scaffold(
        backgroundColor: Color(0xFFC01D1D),
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          _SplashAssets.current,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
