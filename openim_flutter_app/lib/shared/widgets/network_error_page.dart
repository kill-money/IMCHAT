// 统一网络异常页面：离线、超时、服务不可用。
//
// 用法：在需要全屏错误的场景直接使用 [NetworkErrorPage]。
// 在局部场景使用 [NetworkErrorBanner] 做顶部横幅提示。

import 'package:flutter/material.dart';
import '../../core/network/network_interceptor.dart';

class NetworkErrorPage extends StatelessWidget {
  final NetworkException error;
  final VoidCallback? onRetry;

  const NetworkErrorPage({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = _errorContent();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _errorContent() {
    switch (error.type) {
      case NetworkErrorType.offline:
        return (Icons.wifi_off, '无网络连接', '请检查网络设置后重试');
      case NetworkErrorType.timeout:
        return (Icons.timer_off, '请求超时', '服务器响应过慢，请稍后重试');
      case NetworkErrorType.serverUnreachable:
        return (Icons.cloud_off, '服务不可用', '无法连接到服务器');
      case NetworkErrorType.serverError:
        return (Icons.error_outline, '服务器错误', '服务端异常 (${error.statusCode})');
      case NetworkErrorType.unknown:
        return (Icons.help_outline, '未知错误', error.message);
    }
  }
}

/// 顶部横幅：网络恢复后自动隐藏。
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NetworkMonitor.instance.onlineStream,
      initialData: NetworkMonitor.instance.isOnline,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        return AnimatedSlide(
          offset: online ? const Offset(0, -1) : Offset.zero,
          duration: const Duration(milliseconds: 300),
          child: online
              ? const SizedBox.shrink()
              : MaterialBanner(
                  content: const Text('网络已断开，部分功能不可用'),
                  leading: const Icon(Icons.wifi_off, color: Colors.white),
                  backgroundColor: Colors.red[700],
                  contentTextStyle: const TextStyle(color: Colors.white),
                  actions: [
                    TextButton(
                      onPressed: () => NetworkMonitor.instance.checkNow(),
                      child: const Text('检查网络',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
