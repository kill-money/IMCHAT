import 'dart:io' show Platform;
import 'dart:ui' show Color, Size;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';

/// Global tray instance, available for disposal on app exit.
SystemTray? systemTray;

/// Initialize desktop window settings (Windows/macOS/Linux)
Future<void> initDesktopWindow() async {
  if (kIsWeb) return;
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1100, 700),
    minimumSize: Size(800, 600),
    center: true,
    title: 'OpenIM',
    backgroundColor: Color(0x00000000),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Prevent close — minimize to tray instead
  await windowManager.setPreventClose(true);

  // Init system tray (optional: skip on failure so app still runs)
  try {
    await _initSystemTray();
  } catch (_) {
    // Tray icon path or platform may fail; allow app to run without tray
  }
}

Future<void> _initSystemTray() async {
  systemTray = SystemTray();

  // Windows: use runner resources path (assets/app_icon.ico not in pubspec bundle)
  String iconPath = Platform.isWindows
      ? 'resources\\app_icon.ico'
      : 'assets/app_icon.png';

  await systemTray!.initSystemTray(
    title: 'OpenIM',
    iconPath: iconPath,
    toolTip: 'OpenIM - 即时通讯',
  );

  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: '显示窗口',
      onClicked: (_) async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
    MenuSeparator(),
    MenuItemLabel(
      label: '退出',
      onClicked: (_) async {
        await windowManager.setPreventClose(false);
        await windowManager.close();
        systemTray?.destroy();
      },
    ),
  ]);
  await systemTray!.setContextMenu(menu);

  // Double-click tray icon to show window
  systemTray!.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick ||
        eventName == kSystemTrayEventDoubleClick) {
      windowManager.show();
      windowManager.focus();
    }
  });
}

/// Window listener mixin — add to your root widget's State.
/// Call `windowManager.addListener(this)` in initState.
mixin DesktopWindowListener on WindowListener {
  @override
  void onWindowClose() async {
    // Minimize to tray instead of closing
    await windowManager.hide();
  }
}
