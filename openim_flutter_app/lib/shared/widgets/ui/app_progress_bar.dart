import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 全局进度条：高度 6dp，主色
class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0

  const AppProgressBar({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: AppColors.divider,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

