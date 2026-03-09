import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 统一反馈组件 — 禁止在业务代码中直接调用 ScaffoldMessenger / showDialog
/// 所有 Toast 类提示必须通过此类输出，确保样式一致性
class AppFeedback {
  AppFeedback._();

  /// 操作成功提示（绿色）
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ));
  }

  /// 操作失败提示（红色）
  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
      ));
  }

  /// 中性信息提示
  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
  }

  /// 网络异常专用提示
  static void networkError(BuildContext context) {
    error(context, '网络连接失败，请检查网络后重试');
  }

  /// 超时专用提示
  static void timeoutError(BuildContext context) {
    error(context, '网络请求超时，请稍后重试');
  }
}
