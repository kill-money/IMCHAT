import 'package:flutter/material.dart';
import '../../theme/typography.dart';

/// 全局文字组件，禁止直接使用 Text 自定义字号/字重
///
/// 颜色由 [Theme.of(context).colorScheme] 自动适配亮/暗模式；
/// 字体缩放跟随系统，但在 main.dart 中已钳制到 ≤1.3× 防溢出。
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTitle;
  final bool isSmall;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTitle = false,
    this.isSmall = false,
  });

  TextStyle get _baseStyle {
    if (isTitle) return AppTypography.title;
    if (isSmall) return AppTypography.small;
    return AppTypography.body;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // isSmall → 次级信息用 onSurfaceVariant；其余用 onSurface（主文字）
    final defaultColor = isSmall ? cs.onSurfaceVariant : cs.onSurface;
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: _baseStyle.merge(
        style ?? TextStyle(color: defaultColor),
      ),
    );
  }
}
