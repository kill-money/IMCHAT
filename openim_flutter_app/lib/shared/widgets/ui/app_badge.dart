import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 消息红点徽章
class AppBadge extends StatelessWidget {
  final int? count;
  final double size;

  const AppBadge({
    super.key,
    this.count,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (count == null || count == 0) {
      return const SizedBox.shrink();
    }

    final display =
        count! > 99 ? '99+' : count!.toString();

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(size),
      ),
      child: Text(
        display,
        textScaler: const TextScaler.linear(1.0),
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.cardBackground,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

