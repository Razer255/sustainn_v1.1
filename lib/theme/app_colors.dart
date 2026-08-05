import 'package:flutter/material.dart';

/// Sustainn brand colors extracted from the logo.
/// Primary green (#1CBA6F) is the hero color used across buttons,
/// active navigation, headers, and key icons.
class AppColors {
  AppColors._();

  // ─── Primary Palette ───────────────────────────────────────
  static const Color primary = Color(0xFF1CBA6F);
  static const Color primaryDark = Color(0xFF128A52);
  static const Color primaryLight = Color(0xFFDDF5E8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ─── Neutral Text ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFF9E9E9E);

  // ─── Backgrounds ──────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundAlt = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F5F2);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ─── Semantic Colors ──────────────────────────────────────
  static const Color warning = Color(0xFFE8A400);
  static const Color warningLight = Color(0xFFFFF3D0);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerLight = Color(0xFFFFE0E0);
  static const Color success = Color(0xFF1CBA6F);
  static const Color successLight = Color(0xFFDDF5E8);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── Health Status ────────────────────────────────────────
  static const Color healthGood = Color(0xFF1CBA6F);
  static const Color healthModerate = Color(0xFFE8A400);
  static const Color healthPoor = Color(0xFFD64545);

  // ─── Borders & Dividers ───────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // ─── Dark Mode (future use) ───────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // ─── Gradients ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, Color(0xFF15A85F)],
  );
}
