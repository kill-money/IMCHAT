import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';

/// 全局文字组件，禁止直接使用 Text 自定义字号/字重
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
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: const TextScaler.linear(1.0),
      style: _baseStyle.merge(
        style ??
            const TextStyle(
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

