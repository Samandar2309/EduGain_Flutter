// Design tokens for the EduGain "Premium & Clean" visual language.
//
// Everything visual (colour, spacing, radius, shadow, gradient) lives here so
// the look stays consistent and is tweakable from one place. Screens should
// pull from these instead of hard-coding values.
import 'package:flutter/material.dart';

/// Brand + semantic colours. Emerald brand on soft slate surfaces.
abstract final class AppColors {
  // Brand (emerald)
  static const brand = Color(0xFF10B981); // emerald-500
  static const brandDark = Color(0xFF059669); // emerald-600
  static const brandDeep = Color(0xFF047857); // emerald-700
  static const brandTint = Color(0xFFD1FAE5); // emerald-100

  // Neutrals (slate)
  static const ink = Color(0xFF0F172A); // slate-900 — primary text
  static const inkSoft = Color(0xFF475569); // slate-600 — secondary text
  static const inkFaint = Color(0xFF94A3B8); // slate-400 — hints
  static const line = Color(0xFFE2E8F0); // slate-200 — borders
  static const surface = Color(0xFFFFFFFF); // cards
  static const canvas = Color(0xFFF6F8FB); // page background
  static const canvasAlt = Color(0xFFEEF2F7);

  // Module accents (a touch of colour on a clean base)
  static const speaking = Color(0xFF6366F1); // indigo
  static const vocabulary = Color(0xFFF59E0B); // amber
  static const grammar = Color(0xFF0EA5E9); // sky
  static const placement = Color(0xFFF43F5E); // rose

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const streak = Color(0xFFFB923C); // orange — streak flame
  static const xp = Color(0xFFF59E0B); // amber — XP bolt

  // Dark mode
  static const inkDark = Color(0xFF0B1120);
  static const surfaceDark = Color(0xFF131A2A);
  static const canvasDark = Color(0xFF0B1120);
  static const lineDark = Color(0xFF1E293B);
}

/// Brand gradients.
abstract final class AppGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14C28C), Color(0xFF059669)],
  );

  static const brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
  );

  /// Per-module accent gradient (subtle, for icon chips).
  static LinearGradient accent(Color c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c, Color.lerp(c, Colors.black, 0.18)!],
  );
}

/// 4-pt spacing scale.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Corner radii.
abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Soft, premium shadows (low-contrast, large blur).
abstract final class AppShadow {
  static List<BoxShadow> get card => const [
    BoxShadow(
      color: Color(0x0F1E293B), // slate-900 @ ~6%
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> get soft => const [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  /// Coloured glow under a brand element.
  static List<BoxShadow> glow(Color c) => [
    BoxShadow(
      color: c.withValues(alpha: 0.35),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
  ];
}
