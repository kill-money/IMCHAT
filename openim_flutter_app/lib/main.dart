import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/desktop_window.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/conversation_controller.dart';
import 'core/controllers/chat_controller.dart';
import 'core/controllers/wallet_controller.dart';
import 'shared/theme/app_theme.dart';
import 'shared/pages/splash_page.dart';
import 'shared/pages/auth_page.dart';
import 'ui/mobile/mobile_layout.dart';
import 'ui/desktop/desktop_layout.dart';
import 'ui/web/web_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set platform flags
  ApiConfig.isWeb = kIsWeb;
  ApiConfig.isDesktop = !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // 二开：推荐系统 — 从 Web URL 中解析 ?ref= 参数
  if (kIsWeb) {
    final ref = Uri.base.queryParameters['ref'] ?? '';
    if (ref.isNotEmpty) ApiConfig.downloadReferrer = ref;
  }

  // Desktop window config (1100x700, minimize 800x600)
  if (ApiConfig.isDesktop) {
    await initDesktopWindow();
  }

  runApp(const OpenIMApp());
}

class OpenIMApp extends StatelessWidget {
  const OpenIMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ConversationController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => WalletController()), // 二开：钱包系统
      ],
      child: MaterialApp(
        title: '惠泽苍生',
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          // 统一关闭系统字体缩放，textScaleFactor 固定为 1
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashPage(),
          '/login': (_) => const AuthPage(),
          '/home': (_) => _buildHomeLayout(),
        },
      ),
    );
  }

  Widget _buildHomeLayout() {
    if (ApiConfig.isWeb) return const WebLayout();
    if (ApiConfig.isDesktop) return const DesktopLayout();
    return const MobileLayout();
  }
}
