import 'package:flutter/material.dart';

class AppColors {
  /// Set by the top-level widget based on platform brightness.
  static Brightness _brightness = Brightness.light;

  static void setBrightness(Brightness b) => _brightness = b;
  static bool get isDark => _brightness == Brightness.dark;

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surface =>
      isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get surfaceLight =>
      isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

  // ── Accent colors ──────────────────────────────────────────────────────────
  static const primary = Color(0xFF0891B2);       // Teal 600
  static const primaryDark = Color(0xFF0E7490);   // Teal 700
  static const green = Color(0xFF059669);          // Emerald 600
  static const amber = Color(0xFFD97706);          // Amber 600
  static const red = Color(0xFFDC2626);            // Red 600
  static const purple = Color(0xFF7C3AED);         // Violet 600

  // ── Text ────────────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get textHint =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // ── Borders / Dividers ─────────────────────────────────────────────────────
  static Color get border =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // ── Role accents ───────────────────────────────────────────────────────────
  static const riderAccent = Color(0xFF0891B2);
  static const facilityAccent = Color(0xFF059669);
}
