/// 缓存清理 — 桥接文件（自动选择平台实现）
library;

export 'cache_utils_stub.dart' if (dart.library.io) 'cache_utils_io.dart';
