import 'dart:async';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/chat_api.dart';
import 'core/api/group_api.dart';
import 'core/desktop_window.dart';
import 'core/network/network_interceptor.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/conversation_controller.dart';
import 'core/controllers/chat_controller.dart';
import 'core/controllers/wallet_controller.dart';
import 'core/controllers/status_controller.dart'; // 在线状态
import 'core/controllers/group_controller.dart'; // P0：群聊
import 'core/controllers/config_controller.dart'; // 全局配置
import 'core/services/audio_playback_service.dart'; // 语音播放全局服务
import 'core/services/im_polling_service.dart'; // 实时消息轮询
import 'core/services/im_sdk_service.dart'; // OpenIM 原生 SDK 封装
import 'core/services/im_service.dart'; // IM 服务抽象
import 'core/services/sdk_im_service.dart'; // SDK IM 实现
import 'core/services/http_im_service.dart'; // HTTP IM 实现
import 'core/services/notification_sound_service.dart'; // 消息提示音
import 'shared/theme/app_theme.dart';
import 'shared/theme/colors.dart' show AppColors;
import 'shared/pages/splash_page.dart';
import 'shared/pages/auth_page.dart';
import 'shared/pages/forgot_password_page.dart';
import 'shared/pages/privacy_settings_page.dart';
import 'ui/mobile/pages/mobile_about_page.dart';
import 'ui/mobile/pages/mobile_settings_page.dart';
import 'ui/mobile/pages/mobile_chat_page.dart';
import 'ui/mobile/mobile_layout.dart';
import 'ui/desktop/desktop_layout.dart';
import 'ui/web/web_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局 Flutter 框架异常拦截 — 防止系统堆栈暴露到 UI
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Set platform flags
  ApiConfig.isWeb = kIsWeb;
  ApiConfig.isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // 打印实际 API 地址（调试用）
  ApiConfig.debugPrintHost();

  // 启动全局网络监听（离线/在线状态流）
  NetworkMonitor.instance.startListening();

  // 推荐系统 — 从 Web URL 中解析 ?ref= 参数
  if (kIsWeb) {
    final ref = Uri.base.queryParameters['ref'] ?? '';
    if (ref.isNotEmpty) ApiConfig.downloadReferrer = ref;
  }

  // Desktop window config (1100x700, minimize 800x600)
  if (ApiConfig.isDesktop) {
    await initDesktopWindow();
  }

  // 初始化语音播放全局服务（后台播放 AudioContext 配置）
  AudioPlaybackService.instance.init();

  // 初始化 OpenIM 原生 SDK（非 Web 平台）
  await IMSDKService.instance.init();

  // runZonedGuarded 捕获所有未处理异步异常（包括 MissingPluginException）
  runZonedGuarded(
    () => runApp(const OpenIMApp()),
    (error, stack) {
      if (kDebugMode) {
        debugPrint('[ZoneError] $error');
        debugPrint('$stack');
      }
    },
  );
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
        ChangeNotifierProvider(create: (_) => WalletController()), // 钱包系统
        ChangeNotifierProvider(create: (_) => StatusController()), // 在线状态
        ChangeNotifierProvider(create: (_) => GroupController()), // P0：群聊
        ChangeNotifierProvider(create: (_) => ConfigController()), // 全局配置
        ChangeNotifierProvider<IMSDKService>.value(
            value: IMSDKService.instance), // OpenIM SDK
      ],
      child: MaterialApp(
        title: '乡村振兴3.0',
        debugShowCheckedModeBanner: false,
        navigatorKey: ApiConfig.navigatorKey, // Token 过期全局拦截导航
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        builder: (context, child) {
          // 允许系统字体放大，但钳制到 1.3×，防止 UI 溢出
          final mediaQuery = MediaQuery.of(context);
          final rawScale = mediaQuery.textScaler.scale(1.0);
          final clampedScale = rawScale.clamp(1.0, 1.3);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(clampedScale),
            ),
            // 点击空白区域收起键盘
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashPage(),
          '/login': (_) => const AuthPage(),
          '/home': (_) => _buildHomeLayout(),
          '/forgot-password': (_) => const ForgotPasswordPage(),
          '/about': (_) => const MobileAboutPage(),
          '/settings': (_) => const MobileSettingsPage(),
          '/privacy-settings': (_) => const PrivacySettingsPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => MobileChatPage(
                conversationID: id,
                title: '',
                recvID: id,
                sessionType: 1,
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildHomeLayout() {
    if (ApiConfig.isDesktop) return const _HomeWrapper(child: DesktopLayout());
    if (ApiConfig.isWeb) {
      // 窄视口（< 600px）显示移动端布局，方便在浏览器中预览移动端
      return _HomeWrapper(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) return const MobileLayout();
            return const WebLayout();
          },
        ),
      );
    }
    return const _HomeWrapper(child: MobileLayout());
  }
}

/// 登录后初始化：连接 WebSocket + 加载隐私设置
class _HomeWrapper extends StatefulWidget {
  final Widget child;
  const _HomeWrapper({required this.child});

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  StreamSubscription<Uri>? _deepLinkSub;
  IMService? _imService;

  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] _HomeWrapper — connecting WS + starting polling');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final statusCtrl = context.read<StatusController>();
      statusCtrl.connectWebSocket();
      statusCtrl.loadMyPrivacy();

      final cfg = context.read<ConfigController>();

      // ── 创建 IMService 并注入到 Controllers ──────────────────────
      if (cfg.useSDK) {
        _imService = SDKIMService();
        FriendApi.useSDK = true;
        GroupApi.useSDK = true;
        MsgApi.useSDK = true;
        ConversationSettingApi.useSDK = true;
        debugPrint('[IMSDK] HomeWrapper: using SDKIMService');
      } else {
        _imService = HTTPIMService();
        FriendApi.useSDK = false;
        GroupApi.useSDK = false;
        MsgApi.useSDK = false;
        ConversationSettingApi.useSDK = false;
        debugPrint('[IMSDK] HomeWrapper: using HTTPIMService');
      }
      context.read<ChatController>().attachIMService(_imService!);
      context.read<ConversationController>().attachIMService(_imService!);

      // ── 消息提示音 ──────────────────────────────────────────────
      final chatCtrl = context.read<ChatController>();
      NotificationSoundService.instance.init();
      chatCtrl.onNewMessageCallback = (_, __) {
        NotificationSoundService.instance.play();
      };

      // 启动消息轮询（HTTP 模式仍需轮询；SDK 模式也保留作为补充）
      ImPollingService().start(
        convCtrl: context.read<ConversationController>(),
        chatCtrl: context.read<ChatController>(),
      );
      _initDeepLinks();

      // ── OpenIM SDK 登录（useSDK 开关控制） ────────────────────────
      if (cfg.useSDK && IMSDKService.instance.isInitialized) {
        IMSDKService.instance
            .login(ApiConfig.userID, ApiConfig.imToken)
            .then((ok) {
          debugPrint('[IMSDK] HomeWrapper login: $ok');
          if (ok && mounted) {
            context.read<ConversationController>().loadConversations();
          }
        });
      }
    });
  }

  void _initDeepLinks() {
    if (kIsWeb) return; // Web 不需要 app_links
    final appLinks = AppLinks();
    // 处理冷启动链接
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    // 监听热启动链接
    _deepLinkSub = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'openim') return;
    if (uri.path.contains('join_group')) {
      final groupID = uri.queryParameters['group_id'] ?? '';
      final inviter = uri.queryParameters['inviter'] ?? '';
      if (groupID.isNotEmpty && mounted) {
        _showJoinGroupDialog(groupID, inviter);
      }
    }
  }

  void _showJoinGroupDialog(String groupID, String inviterUserID) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('加入群聊'),
        content: Text('你收到一个群邀请，群 ID: $groupID\n是否申请加入？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await GroupApi.joinGroup(
                  groupID: groupID,
                  inviterUserID: inviterUserID,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('申请已发送，等待管理员审核')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('操作失败，请稍后重试')),
                  );
                }
              }
            },
            child: Text('申请加入', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _imService?.dispose();
    ImPollingService().stop();
    context.read<StatusController>().disconnectWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
