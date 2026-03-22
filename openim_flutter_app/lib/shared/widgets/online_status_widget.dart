import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/status_controller.dart';
import '../../core/models/user_status.dart';
import '../theme/colors.dart';

/// 可复用的在线状态组件 — 绿点(在线) / 灰点(离线) + lastSeen 文字
///
/// 用法:
/// ```dart
/// OnlineStatusWidget(userID: 'xxx')              // 自动通过 StatusController 获取
/// OnlineStatusWidget.fromStatus(status)           // 手动传入 UserStatus
/// OnlineStatusWidget(userID: 'xxx', showText: false) // 仅显示圆点
/// ```
class OnlineStatusWidget extends StatelessWidget {
  /// 目标用户 ID — 通过 StatusController 自动订阅
  final String? userID;

  /// 手动传入的状态（优先级高于 userID 自动查询）
  final UserStatus? status;

  /// 是否显示 lastSeen 文字（默认 true）
  final bool showText;

  /// 圆点大小（默认 8）
  final double dotSize;

  /// 文字样式（默认 12px，灰色；在线时绿色）
  final TextStyle? textStyle;

  const OnlineStatusWidget({
    super.key,
    this.userID,
    this.status,
    this.showText = true,
    this.dotSize = 8,
    this.textStyle,
  });

  /// 工厂：直接从 UserStatus 构建（不依赖 Provider）
  const OnlineStatusWidget.fromStatus(
    UserStatus this.status, {
    super.key,
    this.showText = true,
    this.dotSize = 8,
    this.textStyle,
  }) : userID = null;

  @override
  Widget build(BuildContext context) {
    final us = status ?? _resolveFromProvider(context);
    if (us == null) return const SizedBox.shrink();

    final isOnline = us.isOnline;
    final dotColor = isOnline ? AppColors.success : AppColors.textSecondary;

    if (!showText) {
      return _dot(dotColor);
    }

    final defaultStyle = TextStyle(
      fontSize: 12,
      color: isOnline ? AppColors.success : AppColors.textSecondary,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(dotColor),
        const SizedBox(width: 4),
        Text(us.lastSeenText, style: textStyle ?? defaultStyle),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  UserStatus? _resolveFromProvider(BuildContext context) {
    if (userID == null || userID!.isEmpty) return null;
    final ctrl = context.watch<StatusController>();
    return ctrl.getStatus(userID!);
  }
}
