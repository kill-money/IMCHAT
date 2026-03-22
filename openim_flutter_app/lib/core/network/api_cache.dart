// 离线缓存层：API 响应本地持久化 + 断网时自动回退。
//
// 设计：
// 1. 成功的 GET 类请求结果缓存到 SharedPreferences（JSON）
// 2. 断网时自动返回缓存数据 + 标记 `fromCache: true`
// 3. 写操作排队到 RetryQueue，联网后自动重放
//
// 缓存键格式: cache:{api}:{path}:{bodyHash}
// 有效期默认 24 小时（可配置）

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_interceptor.dart';

class CacheEntry {
  final Map<String, dynamic> data;
  final int timestamp;
  final bool fromCache;

  CacheEntry(
      {required this.data, required this.timestamp, this.fromCache = false});

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - timestamp >
      ApiCache.maxAge.inMilliseconds;

  Map<String, dynamic> toJson() => {'data': data, 'timestamp': timestamp};

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'] as Map<String, dynamic>,
        timestamp: json['timestamp'] as int,
        fromCache: true,
      );
}

class ApiCache {
  ApiCache._();
  static final instance = ApiCache._();

  /// 缓存有效期：24 小时
  static const Duration maxAge = Duration(hours: 24);

  /// 最大缓存条目数
  static const int maxEntries = 200;

  SharedPreferences? _prefs;
  final _memCache = <String, CacheEntry>{};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 生成缓存键
  String _key(String path, Map<String, dynamic> body) {
    final hash = md5.convert(utf8.encode(jsonEncode(body))).toString();
    return 'cache:$path:$hash';
  }

  /// 缓存 API 响应
  Future<void> put(String path, Map<String, dynamic> body,
      Map<String, dynamic> response) async {
    final key = _key(path, body);
    final entry = CacheEntry(
      data: response,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _memCache[key] = entry;

    // LRU 淘汰
    while (_memCache.length > maxEntries) {
      _memCache.remove(_memCache.keys.first);
    }

    // 持久化
    try {
      await _prefs?.setString(key, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('[ApiCache] persist error: $e');
    }
  }

  /// 获取缓存。返回 null 表示无缓存或已过期。
  CacheEntry? get(String path, Map<String, dynamic> body) {
    final key = _key(path, body);

    // 内存缓存优先
    final mem = _memCache[key];
    if (mem != null && !mem.isExpired) return mem;

    // 磁盘回退
    final raw = _prefs?.getString(key);
    if (raw != null) {
      try {
        final entry =
            CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (!entry.isExpired) {
          _memCache[key] = entry;
          return entry;
        }
        // 过期清理
        _prefs?.remove(key);
      } catch (_) {
        _prefs?.remove(key);
      }
    }

    return null;
  }

  /// 清理所有缓存
  Future<void> clear() async {
    _memCache.clear();
    final keys = _prefs?.getKeys().where((k) => k.startsWith('cache:')) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}

/// 可缓存的 API 路径规则
class CachePolicy {
  /// 读操作（可缓存）— 路径包含这些关键词的请求自动缓存
  static const _cacheable = [
    '/search',
    '/find',
    '/list',
    '/get',
    '/info',
    '/status',
    '/check',
    '/detail',
    '/page',
    '/dashboard',
    '/count',
  ];

  /// 判断路径是否可缓存
  static bool isCacheable(String path) =>
      _cacheable.any((suffix) => path.contains(suffix));
}

// ─── 写操作重试队列 ──────────────────────────────────────────────────────

class RetryTask {
  final String api; // 'im' | 'chat' | 'admin'
  final String path;
  final Map<String, dynamic> body;
  final int createdAt;
  int retries;

  RetryTask({
    required this.api,
    required this.path,
    required this.body,
    required this.createdAt,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
        'api': api,
        'path': path,
        'body': body,
        'createdAt': createdAt,
        'retries': retries,
      };

  factory RetryTask.fromJson(Map<String, dynamic> json) => RetryTask(
        api: json['api'] as String,
        path: json['path'] as String,
        body: json['body'] as Map<String, dynamic>,
        createdAt: json['createdAt'] as int,
        retries: json['retries'] as int? ?? 0,
      );
}

class RetryQueue {
  RetryQueue._();
  static final instance = RetryQueue._();

  static const int maxRetries = 3;
  static const int maxQueueSize = 100;
  static const String _storageKey = 'retry_queue';

  final List<RetryTask> _queue = [];
  bool _processing = false;

  /// 从持久化恢复队列
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _queue.addAll(
            list.map((e) => RetryTask.fromJson(e as Map<String, dynamic>)));
        debugPrint('[RetryQueue] restored ${_queue.length} tasks');
      } catch (e) {
        debugPrint('[RetryQueue] 恢复队列失败，使用空队列: $e');
      }
    }
  }

  /// 入队写操作
  Future<void> enqueue(RetryTask task) async {
    if (_queue.length >= maxQueueSize) {
      _queue.removeAt(0); // FIFO 淘汰
    }
    _queue.add(task);
    await _persist();
  }

  /// 联网后调用：逐一重放
  Future<void> process(
      Future<Map<String, dynamic>> Function(
              String api, String path, Map<String, dynamic> body)
          sender) async {
    if (_processing || _queue.isEmpty) return;
    if (!NetworkMonitor.instance.isOnline) return;

    _processing = true;
    try {
      final snapshot = List<RetryTask>.from(_queue);
      for (final task in snapshot) {
        try {
          await sender(task.api, task.path, task.body);
          _queue.remove(task);
        } catch (e) {
          task.retries++;
          if (task.retries >= maxRetries) {
            _queue.remove(task);
            debugPrint(
                '[RetryQueue] dropped after $maxRetries retries: ${task.path}');
          }
        }
      }
      await _persist();
    } finally {
      _processing = false;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_queue.map((t) => t.toJson()).toList()));
  }

  int get pendingCount => _queue.length;
}
