// lib/core/theme/app_theme.dart
// ─────────────────────────────────────────────────────────────
// All colors, fonts, and theme config for Gram Seva.
// This is the single source of truth for the design system.
// Change a color here → updates the entire app instantly.
//
// Design system (from our locked design sprint):
//   Primary:    #166534  (deep forest green — trust & belonging)
//   CTA:        #C2440A  (terracotta orange — action & voice)
//   Background: #FAFAF7  (warm off-white — feels like home)
//   Cards:      #FFFFFF  (clean white)
//   Fonts:      Playfair Display (headings) + Inter (body)
//               + Noto Sans Devanagari (Hindi text)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // — Primary green ─────────────────────────────────────────
  static const Color primary        = Color(0xFF166534);  // Deep forest green
  static const Color primaryLight   = Color(0xFFF0FDF4);  // Very light green bg
  static const Color primaryMid     = Color(0xFFDCFCE7);  // Light green for badges
  static const Color primaryBorder  = Color(0xFFBBF7D0);  // Green border
  static const Color primaryDark    = Color(0xFF14532D);  // Darker green for splash

  // — CTA orange ────────────────────────────────────────────
  static const Color cta            = Color(0xFFC2440A);  // Terracotta orange
  static const Color ctaLight       = Color(0xFFFFF4EC);  // Light orange bg
  static const Color ctaBorder      = Color(0xFFFDDCB5);  // Orange border

  // — Neutral / background ──────────────────────────────────
  static const Color background     = Color(0xFFFAFAF7);  // Warm off-white
  static const Color cardBg         = Color(0xFFFFFFFF);  // Card white
  static const Color border         = Color(0xFFE5E7EB);  // Light grey border

  // — Text ──────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A1A1A);  // Near black
  static const Color textSecondary  = Color(0xFF6B7280);  // Medium grey
  static const Color textHint       = Color(0xFF9CA3AF);  // Light grey hint

  // — Semantic ──────────────────────────────────────────────
  static const Color error          = Color(0xFF991B1B);  // Red for errors
  static const Color errorLight     = Color(0xFFFEE2E2);  // Light red bg
  static const Color info           = Color(0xFF1E40AF);  // Blue for info
  static const Color infoLight      = Color(0xFFEFF6FF);  // Light blue bg
}


class AppTheme {
  // — Text styles ───────────────────────────────────────────
  // Playfair Display for headings — elegant serif
  // Inter for body — clean, highly readable
  // Noto Sans Devanagari applied separately for Hindi text

  static TextTheme get textTheme => TextTheme(
    // Large screen titles
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    ),
    // Section headings
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    ),
    // Card titles
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.playfairDisplay(
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
    ),
    // Body text
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint,
    ),
    // Labels and buttons
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cardBg,
    ),
  );

  // — Main theme ────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cardBg,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textHint,
      ),
    ),
  );
}
