import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta exclusiva do motor inteligente (não afeta o restante do app).
abstract final class PermutaInteligenteTheme {
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgPanel = Color(0xFF12182B);
  static const Color bgGlass = Color(0xFF1A2240);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentAmber = Color(0xFFFFAB40);
  static const Color gridLine = Color(0xFF243049);
  static const Color textPrimary = Color(0xFFE8ECF8);
  static const Color textMuted = Color(0xFF8B95B5);

  static ThemeData appBarTheme() {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDeep,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
    );
  }

  static TextStyle titleStyle([double size = 18]) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle monoStyle([double size = 12, Color? color]) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color ?? textMuted,
      );

  static BoxDecoration panelDecoration({Color? borderColor}) => BoxDecoration(
        color: bgPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (borderColor ?? accentPurple).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: accentPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      );

  static BoxDecoration glassCard({Color accent = accentCyan}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgGlass.withValues(alpha: 0.95),
            bgPanel.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      );
}
