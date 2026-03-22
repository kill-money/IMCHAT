/// StatusController — 在线状态 + Last Seen + 隐私设置 状态管理
///
/// 使用方：
///   context.read(StatusController).fetchStatuses(['u1','u2'])
///   context.watch(StatusController).getStatus('u1')?.isOnline
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/status_api.dart';
import '../models/user_status.dart';
import '../services/websocket_service.dart';

class StatusController extends ChangeNotifier {
  // ── LRU 缓存（最多 1000 条，防止 100k+ 用户导致内存无限增长）
  static const int _maxCacheSize = 1000;
  // Dart 默认 Map 即 LinkedHashMap（插入序），可直接用字面量
  final _cache = <String, UserStatus>{};
  final _cacheTs = <String, DateTime>{}; // 缓存写入时间（TTL 用）
  static const Duration _cacheTTL = Duration(seconds: 30);

  // ── 防抖合并（50ms 内的多次请求合并为一次）
  Timer? _debounceTimer;
  final Set<String> _pendingIDs = {};

  final _ws = WebSocketService();

  LastSeenPrivacy _myPrivacy = LastSeenPrivacy.everyone;
  LastSeenPrivacy get myPrivacy => _myPrivacy;

  void debugPrintState() {
    debugPrint(
        '[StatusController] cached=${_cache.length} pending=${_pendingIDs.length} privacy=$_myPrivacy');
  }

  StatusController() {
    // WS 状态变化事件 → 更新缓存
    _ws.onStatusChange = (userID, status) {
      final existing = _cache[userID];
      final isOnline = status == 'online';
      _setCache(
          userID,
          UserStatus(
            userID: userID,
            isOnline: isOnline,
            // 离线时记录当前时间为 lastSeen
            lastSeen: isOnline
                ? existing?.lastSeen
                : DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ));
      notifyListeners();
    };

    // WS 重连后补偿：重新拉取所有缓存用户的状态
    _ws.onReconnect = () {
      final ids = List<String>.from(_cache.keys);
      if (ids.isNotEmpty) {
        _doBatchFetch(ids);
      }
    };
  }

  // ── LRU 辅助 ───────────────────────────────────────────────────────────────

  void _setCache(String userID, UserStatus status) {
    // 已存在则移到末尾（更新 LRU 顺序）
    _cache.remove(userID);
    _cache[userID] = status;
    _cacheTs[userID] = DateTime.now();
    // 超出上限：移除最早访问的条目
    if (_cache.length > _maxCacheSize) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest);
      _cacheTs.remove(oldest);
    }
  }

  // ── WebSocket（Event-Driven: WS 心跳同时刷新 Redis online TTL，无需独立 HTTP 轮询）

  void connectWebSocket() {
    _ws.connect();
  }

  void disconnectWebSocket() {
    // 显式登出 → 立即通知后端离线（不等 TTL 过期）
    StatusApi.goOffline();
    _ws.disconnect();
    _cache.clear();
    _cacheTs.clear();
    notifyListeners();
  }

  // ── 状态查询 ───────────────────────────────────────────────────────────────

  UserStatus? getStatus(String userID) => _cache[userID];

  /// 批量请求：防抖 50ms 合并，跳过 30s 内已缓存的 ID。
  Future<void> fetchStatuses(List<String> userIDs) async {
    final now = DateTime.now();
    for (final id in userIDs) {
      final ts = _cacheTs[id];
      // 已在 TTL 内缓存 → 跳过
      if (ts != null && now.difference(ts) < _cacheTTL) continue;
      _pendingIDs.add(id);
    }
    if (_pendingIDs.isEmpty) return;

    // 防抖：重置 50ms 计时器
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      final ids = List<String>.from(_pendingIDs);
      _pendingIDs.clear();
      _doBatchFetch(ids);
    });
  }

  Future<void> _doBatchFetch(List<String> ids) async {
    // 去重 + 分批 ≤ 100
    final unique = ids.toSet().toList();
    for (var i = 0; i < unique.length; i += 100) {
      final chunk = unique.skip(i).take(100).toList();
      final results = await StatusApi.getBatchStatus(chunk);
      for (final s in results) {
        _setCache(s.userID, s);
      }
    }
    notifyListeners();
  }

  /// 单用户查询（详情页打开时，忽略 TTL 强制刷新）。
  Future<UserStatus?> fetchStatus(String userID) async {
    final s = await StatusApi.getUserStatus(userID);
    if (s != null) {
      _setCache(s.userID, s);
      notifyListeners();
    }
    return s;
  }

  // ── 隐私设置 ───────────────────────────────────────────────────────────────

  Future<void> loadMyPrivacy() async {
    _myPrivacy = await StatusApi.getMyPrivacy();
    notifyListeners();
  }

  Future<bool> setPrivacy(LastSeenPrivacy privacy) async {
    final ok = await StatusApi.setMyPrivacy(privacy);
    if (ok) {
      _myPrivacy = privacy;
      notifyListeners();
    }
    return ok;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
