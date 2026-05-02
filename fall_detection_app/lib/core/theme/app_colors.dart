import 'package:flutter/material.dart';

/// Centralized color palette extracted from the design system.
class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0A1F43);
  static const Color primaryLight = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF10B981);
  static const Color alert = Color(0xFFEF4444);

  // ── Background ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF050B14);
  static const Color cardDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF0B111A);
  static const Color glassDark = Color(0x661E293B); // rgba(30,41,59,0.4)

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textTertiary = Color(0xFF64748B); // slate-500

  // ── Status Colors ────────────────────────────────────────────────
  static const Color safe = accent;
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = alert;

  // ── Metric Icon Backgrounds ──────────────────────────────────────
  static const Color blueGlow = Color(0x1A3B82F6);
  static const Color redGlow = Color(0x1AEF4444);
  static const Color greenGlow = Color(0x1A10B981);
  static const Color purpleGlow = Color(0x1AA855F7);

  // ── Metric Icon Foregrounds ──────────────────────────────────────
  static const Color blueFg = Color(0xFF60A5FA);
  static const Color redFg = Color(0xFFF87171);
  static const Color greenFg = Color(0xFF34D399);
  static const Color purpleFg = Color(0xFFC084FC);

  // ── Glass border ─────────────────────────────────────────────────
  static const Color glassBorder = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color glassBorderLight = Color(0x1AFFFFFF);

  // ── Nav bar ──────────────────────────────────────────────────────
  static const Color navBarBg = Color(0xE60B111A); // ~90% opacity
  static const Color navBarBorder = Color(0x0DFFFFFF);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient callGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF1E3A8A)],
  );

  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
  );

  static const LinearGradient alertBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF450A0A), Color(0xFF1C0404)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1F43), Color(0xFF050B14)],
  );
}
