import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Centralized design tokens for the AIdea editorial design system.
class AppTheme {
  AppTheme._();

  // ─── Colors ───────────────────────────────────────────────────────
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color coral = Color(0xFFE65C5C);
  static const Color error = Color(0xFFB91C1C);
  static const Color alert = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // Light mode
  static const Color lightBg = Color(0xFFFAFBFC);
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightSurfaceHigh = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Dark mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceHigh = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkDivider = Color(0xFF334155);

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // ─── Spacing ──────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ─── Radii ────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24.0;
  static const double radiusXl = 100.0; // Fully round for pills
  static const double radiusFull = 100.0;

  // ─── Typography ───────────────────────────────────────────────────
  static TextStyle headline1({Color? color}) => GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headline2({Color? color}) => GoogleFonts.manrope(
        fontSize: _isAndroid ? 30 : 28,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: _isAndroid ? -0.2 : -0.3,
        color: color,
      );

  static TextStyle headline3({Color? color}) => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle titleLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
        fontSize: _isAndroid ? 17 : 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: _isAndroid ? 17 : 16,
        fontWeight: _isAndroid ? FontWeight.w500 : FontWeight.w400,
        height: _isAndroid ? 1.55 : 1.6,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: _isAndroid ? 16 : 14,
        fontWeight: _isAndroid ? FontWeight.w500 : FontWeight.w400,
        height: _isAndroid ? 1.45 : 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: _isAndroid ? 13 : 12,
        fontWeight: _isAndroid ? FontWeight.w500 : FontWeight.w400,
        color: color,
      );

  static TextStyle labelLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: _isAndroid ? 15 : 14,
        fontWeight: FontWeight.w800,
        letterSpacing: _isAndroid ? 0.2 : 0.5,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.manrope(
        fontSize: _isAndroid ? 11.5 : 10,
        fontWeight: FontWeight.w800,
        letterSpacing: _isAndroid ? 1.2 : 1.5,
        color: color,
      );

  static TextStyle button({Color? color}) => GoogleFonts.manrope(
        fontSize: _isAndroid ? 17 : 15,
        fontWeight: FontWeight.w800,
        letterSpacing: _isAndroid ? 0.1 : 0.3,
        color: color,
      );

  // ─── Theme Data Builders ──────────────────────────────────────────

  static ThemeData buildLightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: lightBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme.copyWith(
        primary: seedColor,
        secondary: coral,
      ),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: seedColor.withValues(alpha: 0.5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        hintStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightTextPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: button(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          side: BorderSide(color: lightDivider),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: labelLarge(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData buildDarkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: darkBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        primary: seedColor,
        secondary: coral,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: seedColor.withValues(alpha: 0.5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        hintStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTextPrimary,
          foregroundColor: darkBg,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: button(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          side: BorderSide(color: darkDivider),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: labelLarge(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }

  static MarkdownStyleSheet markdownStyle(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final secondaryTextColor = isDark ? darkTextSecondary : lightTextSecondary;

    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        fontSize: 16,
        height: 1.8,
        color: textColor,
        letterSpacing: 0.1,
      ),
      h1: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      h2: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      h3: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      listBullet: GoogleFonts.inter(
        fontSize: 16,
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      blockquote: GoogleFonts.inter(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        color: secondaryTextColor,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 4),
        ),
      ),
      code: GoogleFonts.firaCode(
        fontSize: 14,
        backgroundColor: isDark ? darkSurfaceHigh : lightSurfaceHigh,
        color: primaryColor,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? darkSurfaceHigh : lightSurfaceHigh,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      a: TextStyle(color: primaryColor, decoration: TextDecoration.underline),
    );
  }
}
