import 'package:flutter/material.dart';

/// Shared design tokens — dark and light variants.
/// Access via: final c = context.c;
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color night;
  final Color card;
  final Color card2;
  final Color border;
  final Color border2;
  final Color amber;
  final Color amberSoft;
  final Color amberD;
  final Color amberDim;
  final Color sage;
  final Color sageDim;
  final Color rose;
  final Color roseDim;
  final Color white;
  final Color muted2;

  const AppColors({
    required this.bg,
    required this.night,
    required this.card,
    required this.card2,
    required this.border,
    required this.border2,
    required this.amber,
    required this.amberSoft,
    required this.amberD,
    required this.amberDim,
    required this.sage,
    required this.sageDim,
    required this.rose,
    required this.roseDim,
    required this.white,
    required this.muted2,
  });

  // ── Dark (default) ──────────────────────────────────────────────────────────
  static const dark = AppColors(
    bg: Color(0xFF0A0C10),
    night: Color(0xFF0B0D11),
    card: Color(0xFF181A21),
    card2: Color(0xFF1E2029),
    border: Color(0x12FFFFFF),
    border2: Color(0x21FFFFFF),
    amber: Color(0xFFFF7F2A),
    amberSoft: Color(0xFFFF9A55),
    amberD: Color(0xFFD96820),
    amberDim: Color(0x1CFF7F2A),
    sage: Color(0xFF4CAF82),
    sageDim: Color(0x1C4CAF82),
    rose: Color(0xFFD4607A),
    roseDim: Color(0x1CD4607A),
    white: Color(0xFFF0F2F5),
    muted2: Color(0x9EF0F2F5),
  );

  // ── Light ───────────────────────────────────────────────────────────────────
  static const light = AppColors(
    bg: Color(0xFFF5F6FA),
    night: Color(0xFFECEDF2),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF2F3F8),
    border: Color(0x0A000000),
    border2: Color(0x1A000000),
    amber: Color(0xFFFF7F2A),
    amberSoft: Color(0xFFFF9A55),
    amberD: Color(0xFFD96820),
    amberDim: Color(0x1CFF7F2A),
    sage: Color(0xFF4CAF82),
    sageDim: Color(0x1C4CAF82),
    rose: Color(0xFFD4607A),
    roseDim: Color(0x1CD4607A),
    white: Color(0xFF0D0F14),
    muted2: Color(0x9E0D0F14),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? night,
    Color? card,
    Color? card2,
    Color? border,
    Color? border2,
    Color? amber,
    Color? amberSoft,
    Color? amberD,
    Color? amberDim,
    Color? sage,
    Color? sageDim,
    Color? rose,
    Color? roseDim,
    Color? white,
    Color? muted2,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      night: night ?? this.night,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberD: amberD ?? this.amberD,
      amberDim: amberDim ?? this.amberDim,
      sage: sage ?? this.sage,
      sageDim: sageDim ?? this.sageDim,
      rose: rose ?? this.rose,
      roseDim: roseDim ?? this.roseDim,
      white: white ?? this.white,
      muted2: muted2 ?? this.muted2,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      night: Color.lerp(night, other.night, t)!,
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      amberD: Color.lerp(amberD, other.amberD, t)!,
      amberDim: Color.lerp(amberDim, other.amberDim, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageDim: Color.lerp(sageDim, other.sageDim, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseDim: Color.lerp(roseDim, other.roseDim, t)!,
      white: Color.lerp(white, other.white, t)!,
      muted2: Color.lerp(muted2, other.muted2, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  /// Shortcut: `final c = context.c;`
  AppColors get c => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
