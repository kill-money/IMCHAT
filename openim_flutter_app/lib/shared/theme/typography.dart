import 'package:flutter/material.dart';
import 'colors.dart';

/// 全局排版系统
class AppTypography {
  // 标题：20sp SemiBold
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
    fontFamilyFallback: ['PingFang SC', 'Roboto', 'Noto Sans SC'],
  );

  // 正文：16sp Regular
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
    fontFamilyFallback: ['PingFang SC', 'Roboto', 'Noto Sans SC'],
  );

  // 小字：14sp Regular
  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
    fontFamilyFallback: ['PingFang SC', 'Roboto', 'Noto Sans SC'],
  );
}

