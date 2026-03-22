// 全局网络拦截器：统一异常处理 + 自动重试 ≤ 2 次 + 离线检测。
//
// 所有 API 请求通过 [NetworkInterceptor.execute] 包裹，实现：
// 1. 连接前检查网络可达性（ConnectivityResult.none → 直接抛 [NetworkException]）
// 2. 网络异常 / 超时自动重试（指数退避 1s → 2s，最多 2 次）
// 3. 标准错误结构 NetworkException 供 UI 统一消费

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// ─── 异常体系 ─────────────────────────────────────────────────────────────

enum NetworkErrorType {
  /// 设备离线（WiFi/移动数据均不可用）
  offline,

  /// 请求超时
  timeout,

  /// 服务端无响应 / DNS 解析失败 / 连接被拒
  serverUnreachable,

  /// HTTP 非 2xx（含 5xx）
  serverError,

  /// 其他未分类异常
  unknown,
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  const NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  bool get isRetryable =>
      type == NetworkErrorType.timeout ||
      type == NetworkErrorType.serverUnreachable ||
      (type == NetworkErrorType.serverError &&
          statusCode != null &&
          statusCode! >= 500);

  @override
  String toString() => 'NetworkException($type, $message)';
}

// ─── 全局网络状态流 ───────────────────────────────────────────────────────

class NetworkMonitor {
  NetworkMonitor._();
  static final instance = NetworkMonitor._();

  final _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .distinct();

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  void startListening() {
    onlineStream.listen((online) {
      _isOnline = online;
      debugPrint('[NetworkMonitor] online=$online');
    });
  }
}

// ─── 拦截器核心 ───────────────────────────────────────────────────────────

class NetworkInterceptor {
  /// 最大重试次数（不含首次请求）
  static const int _maxRetries = 2;

  /// 包裹任意异步请求，统一错误处理 + 自动重试。
  ///
  /// [request] 为实际的 HTTP 调用闭包。
  /// 返回值与原始调用一致。
  static Future<T> execute<T>(Future<T> Function() request) async {
    // 预检：仅作日志提示，不阻塞请求——connectivity_plus 在部分 Android
    // 版本（如 API 36）会误报 offline，因此始终尝试发起请求。
    final preCheck = await NetworkMonitor.instance.checkNow();
    if (!preCheck) {
      debugPrint('[NetworkInterceptor] connectivity reports offline, '
          'still attempting request');
    }

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await request();
      } on NetworkException catch (e) {
        lastError = e;
        if (!e.isRetryable || attempt == _maxRetries) rethrow;
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt == _maxRetries) {
          throw NetworkException(
            type: NetworkErrorType.timeout,
            message: '请求超时',
            cause: e,
          );
        }
      } on SocketException catch (e) {
        lastError = e;
        if (attempt == _maxRetries) {
          throw NetworkException(
            type: NetworkErrorType.serverUnreachable,
            message: '无法连接服务器',
            cause: e,
          );
        }
      } catch (e) {
        // 非网络异常（如 JSON 解析错误）不重试
        throw NetworkException(
          type: NetworkErrorType.unknown,
          message: e.toString(),
          cause: e,
        );
      }

      // 指数退避：1s, 2s
      final delay = Duration(seconds: 1 << attempt);
      debugPrint(
          '[NetworkInterceptor] retry ${attempt + 1}/$_maxRetries after $delay (cause: $lastError)');
      await Future.delayed(delay);

      // 重试前检查网络（仅日志，不阻塞）
      if (!await NetworkMonitor.instance.checkNow()) {
        debugPrint('[NetworkInterceptor] connectivity still reports offline, '
            'retrying anyway');
      }
    }

    // 理论上不可达
    throw NetworkException(
      type: NetworkErrorType.unknown,
      message: '请求失败',
      cause: lastError,
    );
  }
}
