import 'package:flutter/material.dart';

/// 全局颜色配置 - 乡村振兴公益主题（中国红·丰收金·山河蓝）
class AppColors {
  // ── 主色与辅助色 ────────────────────────────────────────────────────
  static const Color primary = Color(0xFFC62828); // 中国红（扶贫/党建）
  static const Color accent = Color(0xFFEF5350); // 浅红（辅助）
  static const Color harvest = Color(0xFFF9A825); // 丰收金（农业/乡村）
  static const Color sky = Color(0xFF0D47A1); // 山河蓝（就业/教育）

  // ── 扩展语义色 ──────────────────────────────────────────────────────
  static const Color activity = Color(0xFFF57C00); // 橙色（活动/援助/预警）
  static const Color purple = Color(0xFF6A1B9A); // 紫色（报表/隐私/分析）
  static const Color teal = Color(0xFF0097A7); // 青色（语言/通用设置）
  static const Color indigo = Color(0xFF5C6BC0); // 靛蓝（图库/照片）

  // ── 渐变 ────────────────────────────────────────────────────────────
  /// 大头图红色渐变（主 Banner）
  static const List<Color> primaryGradient = [
    Color(0xFF8E0000),
    Color(0xFFB71C1C),
    Color(0xFFC62828),
  ];

  /// Banner 轮播背景色组（红/蓝/绿/橙）
  static const List<Color> bannerRed = [Color(0xFF8E0000), Color(0xFFD32F2F)];
  static const List<Color> bannerGreen = [Color(0xFF1B5E20), Color(0xFF43A047)];
  static const List<Color> bannerBlue = [Color(0xFF0D47A1), Color(0xFF42A5F5)];
  static const List<Color> bannerOrange = [
    Color(0xFFE65100),
    Color(0xFFFFB74D)
  ];

  // ── 状态色 ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF388E3C);
  static const Color danger = Color(0xFFD32F2F);
  static const Color disabled = Color(0xFFBDBDBD);

  // ── 亮色模式 背景/文本 ──────────────────────────────────────────────
  static const Color pageBackground = Color(0xFFF5F7FA); // 浅灰白
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFFFFFFF); // 卡片背景（统一入口）
  static const Color accentSurface = Color(0xFFFFEBEE); // 浅红提示背景（公告 Banner）

  static const Color textPrimary = Color(0xFF111111); // 主文字（对比度 ≥ 7:1）
  static const Color textSecondary = Color(0xFF666666); // 辅助文字（对比度 ≥ 4.5:1）
  static const Color textOnPrimary = Colors.white;

  static const Color divider = Color(0xFFEEEEEE);
  static const Color mask = Color.fromRGBO(0, 0, 0, 0.6);
  static const Color shadow = Color(0x0F000000);

  // ── 暗色模式 背景/文本 ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkDivider = Color(0xFF2E2E2E);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  /// 暗色模式下的主红（较亮，保证对比度）
  static const Color primaryDark = Color(0xFFEF5350);

  // ── WCAG 对比度工具 ────────────────────────────────────────────────
  /// 确保彩色文字在浅色调底（12% alpha）上满足 WCAG AA (≥ 4.5 : 1)。
  /// 亮度 > 0.10 的颜色会被加深（50% 黑色叠加）；仅极深色直接返回。
  /// 暗色模式下直接返回原色（亮色字在深底上天然高对比）。
  static Color contrastSafe(Color c, Brightness brightness) {
    if (brightness == Brightness.dark) return c;
    if (c.computeLuminance() <= 0.10) return c;
    return Color.alphaBlend(const Color(0x80000000), c);
  }
}
