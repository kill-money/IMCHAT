/// 缓存清理 — Native 平台实现（Android/iOS/Windows/macOS/Linux）
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 清除本地缓存目录，返回释放的字节数。
Future<int> clearAppCache() async {
  int totalBytes = 0;

  final tempDir = await getTemporaryDirectory();
  if (tempDir.existsSync()) {
    totalBytes += await _dirSize(tempDir);
    await _clearDir(tempDir);
  }

  try {
    final cacheDir = await getApplicationCacheDirectory();
    if (cacheDir.existsSync() && cacheDir.path != tempDir.path) {
      totalBytes += await _dirSize(cacheDir);
      await _clearDir(cacheDir);
    }
  } catch (e) {
    // 部分平台不支持 getApplicationCacheDirectory
    debugPrint('清理应用缓存目录失败: $e');
  }

  return totalBytes;
}

Future<void> _clearDir(Directory dir) async {
  await for (final entity in dir.list()) {
    try {
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('删除缓存条目失败: ${entity.path} - $e');
    }
  }
}

Future<int> _dirSize(Directory dir) async {
  int total = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
  } catch (e) {
    debugPrint('计算缓存大小失败: $e');
  }
  return total;
}
