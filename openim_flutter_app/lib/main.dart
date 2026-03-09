import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/desktop_window.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/conversation_controller.dart';
import 'core/controllers/chat_controller.dart';
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
      ],
      child: MaterialApp(
        title: '惠泽苍生',
        debugShowCheckedModeBanner: false,
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
