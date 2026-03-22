/// Device info utilities — platform ID and persistent device identifier.
library;

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Returns the OpenIM platform ID for the current device.
///
/// Enum matches openim-tools constantpb:
///   iOS=1  Android=2  Web=3  Windows=4  macOS=5  Linux=6
int getCurrentPlatformId() {
  if (kIsWeb) return 3;
  if (Platform.isIOS) return 1;
  if (Platform.isAndroid) return 2;
  if (Platform.isWindows) return 4;
  if (Platform.isMacOS) return 5;
  return 6; // Linux
}

/// Returns a human-readable name for the current platform.
String getCurrentPlatformName() {
  if (kIsWeb) return 'Web';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  return 'Linux';
}

/// Generates a RFC 4122 v4 UUID using a cryptographically-secure RNG.
String _generateDeviceId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  String h(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${h(bytes[0])}${h(bytes[1])}${h(bytes[2])}${h(bytes[3])}'
      '-${h(bytes[4])}${h(bytes[5])}'
      '-${h(bytes[6])}${h(bytes[7])}'
      '-${h(bytes[8])}${h(bytes[9])}'
      '-${h(bytes[10])}${h(bytes[11])}${h(bytes[12])}'
      '${h(bytes[13])}${h(bytes[14])}${h(bytes[15])}';
}

/// Returns a stable device ID, generating and persisting one on first call.
///
/// Storage: `<applicationSupportDirectory>/.device_id` (plain text UUID).
/// Web: returns a session-random ID (no file system access).
/// Errors: silently falls back to a new random ID.
Future<String> getOrCreateDeviceId() async {
  if (kIsWeb) {
    // No persistent storage on web — generate an ephemeral ID per session.
    return 'web-${_generateDeviceId()}';
  }
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}.device_id');
    if (await file.exists()) {
      final stored = (await file.readAsString()).trim();
      if (stored.isNotEmpty) return stored;
    }
    final newId = _generateDeviceId();
    await file.writeAsString(newId);
    return newId;
  } catch (_) {
    // File I/O error: return ephemeral ID; next call will retry storage.
    return _generateDeviceId();
  }
}
