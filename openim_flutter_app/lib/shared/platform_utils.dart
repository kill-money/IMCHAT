import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Platform-aware utility values for consistent UI scaling across platforms.
class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Font sizes
  static double get bodyFontSize => isWeb ? 14 : isDesktop ? 13 : 15;
  static double get titleFontSize => isWeb ? 16 : isDesktop ? 15 : 17;
  static double get smallFontSize => isWeb ? 12 : isDesktop ? 11 : 13;

  // Spacing
  static double get itemPadding => isDesktop ? 8 : 12;
  static double get avatarSize => isDesktop ? 40 : 46;

  // Bubble max width factor
  static double get bubbleMaxWidthFactor => isDesktop ? 0.5 : isWeb ? 0.55 : 0.65;
}
