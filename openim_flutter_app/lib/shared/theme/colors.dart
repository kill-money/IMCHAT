import 'package:flutter/material.dart';

/// 全局颜色配置 - 国家扶贫公益主题（中国红·丰收金·暖米白）
class AppColors {
  // 主色与辅助色
  static const Color primary = Color(0xFFC62828); // 中国红
  static const Color accent = Color(0xFFF9A825);  // 丰收金

  // 状态色
  static const Color success = Color(0xFF388E3C);
  static const Color danger  = Color(0xFFB71C1C);
  static const Color disabled = Color(0xFFBDBDBD);

  // 背景色
  static const Color pageBackground = Color(0xFFFFF8F0); // 暖米白
  static const Color cardBackground = Colors.white;

  // 文本色
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  // 分割线
  static const Color divider = Color(0xFFEEEEEE);

  // 遮罩
  static const Color mask = Color.fromRGBO(0, 0, 0, 0.6);

  // 阴影色
  static const Color shadow = Color(0x0F000000);
}
