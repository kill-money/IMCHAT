import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  // ─────────────────────────── 亮色主题 ────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pageBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.cardBackground,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      surfaceContainerLow: AppColors.pageBackground,
    ),

    // ── AppBar ──────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.appBar,
      iconTheme: IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
      surfaceTintColor: Colors.transparent,
    ),

    // ── 输入框 ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      floatingLabelStyle:
          AppTypography.small.copyWith(color: AppColors.primary),
    ),

    // ── ElevatedButton ───────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.disabled;
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.85);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.92);
          }
          return AppColors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.white70;
          return Colors.white;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 2;
          return 0;
        }),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        )),
        textStyle: WidgetStateProperty.all(AppTypography.button),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl)),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.disabled;
          return AppColors.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppColors.disabled);
          }
          return const BorderSide(color: AppColors.primary);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        )),
        textStyle: WidgetStateProperty.all(AppTypography.button
            .copyWith(color: AppColors.primary, letterSpacing: 1.0)),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl)),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.small
            .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
    ),

    // ── FloatingActionButton ────────────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── AlertDialog ─────────────────────────────────────────────────
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: AppTypography.subtitle.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle:
          AppTypography.body.copyWith(color: AppColors.textPrimary),
    ),

    // ── Switch ──────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.disabled;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.35);
        }
        return AppColors.divider;
      }),
    ),

    // ── SnackBar ────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
    ),

    // ── Divider ─────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 0.5,
      space: 0,
    ),

    // ── ListTile ─────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      iconColor: AppColors.primary,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.07),
      selectedColor: AppColors.primary,
    ),

    // ── TextTheme ────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayMedium:
          AppTypography.display.copyWith(color: AppColors.textPrimary),
      titleLarge: AppTypography.title.copyWith(color: AppColors.textPrimary),
      titleMedium:
          AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
      bodyLarge:
          AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimary),
      bodySmall: AppTypography.small.copyWith(color: AppColors.textSecondary),
      labelMedium: AppTypography.label.copyWith(color: AppColors.textPrimary),
      labelSmall:
          AppTypography.caption.copyWith(color: AppColors.textSecondary),
    ),

    // ── BottomNavigationBar ──────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBackground,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      unselectedLabelStyle:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 24),
      elevation: 8,
    ),

    // ── Chip ────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: AppTypography.small.copyWith(color: AppColors.textPrimary),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─────────────────────────── 暗色主题 ────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: Color(0xFFEF9A9A), // 暗色模式辅助色（浅红）
      surface: AppColors.darkSurface,
      error: Color(0xFFCF6679),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF1A1A1A),
      onSurface: AppColors.darkTextPrimary,
      onError: Colors.black,
      surfaceContainerLow: AppColors.darkCard,
    ),

    // ── AppBar ──────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.appBar,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      actionsIconTheme:
          IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      surfaceTintColor: Colors.transparent,
    ),

    // ── 输入框 ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.darkDivider.withValues(alpha: 0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
      ),
      hintStyle:
          AppTypography.body.copyWith(color: AppColors.darkTextSecondary),
      prefixIconColor: AppColors.darkTextSecondary,
      suffixIconColor: AppColors.darkTextSecondary,
      labelStyle:
          AppTypography.body.copyWith(color: AppColors.darkTextSecondary),
      floatingLabelStyle:
          AppTypography.small.copyWith(color: AppColors.primaryDark),
    ),

    // ── ElevatedButton ───────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF424242);
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryDark.withValues(alpha: 0.85);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primaryDark.withValues(alpha: 0.92);
          }
          return AppColors.primaryDark;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF757575);
          }
          return Colors.white;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.10);
          }
          return null;
        }),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        )),
        textStyle: WidgetStateProperty.all(AppTypography.button),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl)),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF616161);
          }
          return AppColors.primaryDark;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: Color(0xFF616161));
          }
          return const BorderSide(color: AppColors.primaryDark);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryDark.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primaryDark.withValues(alpha: 0.08);
          }
          return null;
        }),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        )),
        textStyle: WidgetStateProperty.all(AppTypography.button
            .copyWith(color: AppColors.primaryDark, letterSpacing: 1.0)),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl)),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: AppTypography.small.copyWith(
            color: AppColors.primaryDark, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
    ),

    // ── FloatingActionButton ────────────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── AlertDialog ─────────────────────────────────────────────────
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: AppTypography.subtitle.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle:
          AppTypography.body.copyWith(color: AppColors.darkTextPrimary),
    ),

    // ── Switch ──────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryDark;
        return const Color(0xFF616161);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryDark.withValues(alpha: 0.45);
        }
        return AppColors.darkDivider;
      }),
    ),

    // ── SnackBar ────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF424242),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
    ),

    // ── Divider ─────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 0.5,
      space: 0,
    ),

    // ── ListTile ─────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      iconColor: AppColors.primaryDark,
      tileColor: AppColors.darkSurface,
      selectedTileColor: AppColors.primaryDark.withValues(alpha: 0.12),
      selectedColor: AppColors.primaryDark,
    ),

    // ── TextTheme ────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayMedium:
          AppTypography.display.copyWith(color: AppColors.darkTextPrimary),
      titleLarge:
          AppTypography.title.copyWith(color: AppColors.darkTextPrimary),
      titleMedium:
          AppTypography.subtitle.copyWith(color: AppColors.darkTextPrimary),
      bodyLarge:
          AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      bodyMedium: AppTypography.body.copyWith(color: AppColors.darkTextPrimary),
      bodySmall:
          AppTypography.small.copyWith(color: AppColors.darkTextSecondary),
      labelMedium:
          AppTypography.label.copyWith(color: AppColors.darkTextPrimary),
      labelSmall:
          AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
    ),

    // ── BottomNavigationBar ──────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.darkTextSecondary,
      backgroundColor: AppColors.darkSurface,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      unselectedLabelStyle:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 24),
      elevation: 8,
    ),

    // ── Chip ────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryDark.withValues(alpha: 0.12),
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.25),
      labelStyle:
          AppTypography.small.copyWith(color: AppColors.darkTextPrimary),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
