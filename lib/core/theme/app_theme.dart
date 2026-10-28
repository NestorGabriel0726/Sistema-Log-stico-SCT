import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  // ─── Paleta claro ────────────────────────────────────────────────────────
  static final _colorSchemeLight = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brandSubtle,
    onPrimaryContainer: AppColors.brandDark,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE6F4F3),
    onSecondaryContainer: const Color(0xFF0D4A44),
    tertiary: AppColors.warning,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerBg,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderMuted,
    surfaceContainerHighest: AppColors.surfaceElevated,
    surfaceContainerHigh: AppColors.surfaceElevated,
    surfaceContainer: AppColors.canvasLight,
    surfaceContainerLow: AppColors.canvasLight,
    surfaceContainerLowest: Colors.white,
    scrim: const Color(0x44000000),
    inverseSurface: AppColors.surfaceDark,
    onInverseSurface: AppColors.textPrimaryDark,
    inversePrimary: AppColors.brandLight,
  );

  // ─── Paleta escura ────────────────────────────────────────────────────────
  static final _colorSchemeDark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandLight,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF0E3568),
    onPrimaryContainer: AppColors.brandLight,
    secondary: const Color(0xFF47B5AA),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFF0C302C),
    onSecondaryContainer: const Color(0xFF7FD9D0),
    tertiary: const Color(0xFFE09A40),
    onTertiary: Colors.white,
    error: const Color(0xFFE07070),
    onError: Colors.white,
    errorContainer: AppColors.dangerBgDark,
    onErrorContainer: const Color(0xFFE07070),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderMutedDark,
    surfaceContainerHighest: AppColors.surfaceElevatedDark,
    surfaceContainerHigh: AppColors.surfaceElevatedDark,
    surfaceContainer: AppColors.canvasDark,
    surfaceContainerLow: AppColors.canvasDark,
    surfaceContainerLowest: const Color(0xFF0A1220),
    scrim: const Color(0x88000000),
    inverseSurface: AppColors.surfaceLight,
    onInverseSurface: AppColors.textPrimaryLight,
    inversePrimary: AppColors.brand,
  );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final cs = isLight ? _colorSchemeLight : _colorSchemeDark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: isLight ? AppColors.canvasLight : AppColors.canvasDark,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.25),
      displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w300),
      displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w300),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.25),
      headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );

    return base.copyWith(
      textTheme: textTheme,

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        foregroundColor: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isLight
            ? AppColors.borderLight.withValues(alpha: 0.5)
            : AppColors.borderDark.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(
          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
        ),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Botões ───────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: const BorderSide(color: AppColors.brand),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size(64, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ─── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      // ─── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surfaceLight : AppColors.surfaceElevatedDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isLight ? AppColors.textMutedLight : AppColors.textMutedDark,
          fontSize: 14,
        ),
        isDense: false,
      ),

      // ─── Navigation bar (mobile) ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        indicatorColor: AppColors.brand.withValues(alpha: 0.12),
        height: 68,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.brand, size: 22);
          }
          return IconThemeData(
            color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : (isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark),
          );
        }),
      ),

      // ─── Navigation rail (desktop) ────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        indicatorColor: AppColors.brand.withValues(alpha: 0.1),
        selectedIconTheme: const IconThemeData(color: AppColors.brand, size: 22),
        unselectedIconTheme: IconThemeData(
          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
          size: 22,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
        ),
        elevation: 0,
        labelType: NavigationRailLabelType.all,
      ),

      // ─── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.borderLight : AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.surfaceElevated : AppColors.surfaceElevatedDark,
        selectedColor: AppColors.brand.withValues(alpha: 0.12),
        checkmarkColor: AppColors.brand,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ─── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        minLeadingWidth: 24,
        iconColor: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
        ),
      ),

      // ─── BottomSheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        elevation: 4,
        modalBackgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        dragHandleColor: isLight ? AppColors.borderLight : AppColors.borderDark,
        showDragHandle: true,
      ),

      // ─── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        elevation: 8,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
      ),

      // ─── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.textPrimaryLight : AppColors.surfaceElevatedDark,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isLight ? AppColors.textPrimaryDark : AppColors.textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        elevation: 4,
        actionTextColor: AppColors.brandLight,
      ),

      // ─── Switch / Checkbox ────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.white;
          return isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.brand;
          return isLight ? AppColors.borderLight : AppColors.borderDark;
        }),
      ),

      // ─── PopupMenu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        elevation: 4,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // ─── Progress Indicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.borderLight,
      ),
    );
  }
}
