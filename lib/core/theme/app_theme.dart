import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primárias
  static const primary     = Color(0xFF007AFF);
  static const primaryDark = Color(0xFF0055CC);

  // Backgrounds
  static const background  = Color(0xFFF2F2F7); // iOS system grouped background
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF9F9FB);

  // Texto
  static const textPrimary   = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary  = Color(0xFFC7C7CC);

  // Separadores
  static const divider     = Color(0xFFE5E5EA);
  static const dividerHard = Color(0xFFC6C6C8);

  // Semânticas
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9F0A);
  static const error   = Color(0xFFFF3B30);
  static const purple  = Color(0xFFAF52DE);

  // Gradiente do card principal
  static const gradientStart = Color(0xFF007AFF);
  static const gradientEnd   = Color(0xFF0040CC);
}

class AppTheme {
  static ThemeData get light {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
        primary:    AppColors.primary,
        surface:    AppColors.surface,
        onSurface:  AppColors.textPrimary,
        onPrimary:  Colors.white,
        secondary:  AppColors.primaryDark,
        error:      AppColors.error,
      ),

      // Fonte via google_fonts — carrega automaticamente no web
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
            fontSize: 34, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.8, height: 1.1),
        titleLarge: base.titleLarge?.copyWith(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.3),
        titleMedium: base.titleMedium?.copyWith(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary, letterSpacing: -0.2),
        bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 17, fontWeight: FontWeight.w400,
            color: AppColors.textPrimary, height: 1.5),
        bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 15, fontWeight: FontWeight.w400,
            color: AppColors.textSecondary, height: 1.4),
        bodySmall: base.bodySmall?.copyWith(
            fontSize: 13, fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
        labelLarge: base.labelLarge?.copyWith(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: Colors.white, letterSpacing: -0.1),
      ),

      // Botão principal
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Card
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 34, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.8),
        iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.primary, size: 22),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15),
        hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiary, fontSize: 15),
        errorStyle: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // CircularProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}

// ── Helpers de estilo reutilizáveis ────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4,  offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6,  offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> primaryGlow(Color color) => [
    BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
  ];
}

class AppRadius {
  static const xs  = 8.0;
  static const sm  = 12.0;
  static const md  = 16.0;
  static const lg  = 20.0;
  static const xl  = 24.0;
  static const xxl = 32.0;
}

class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}
