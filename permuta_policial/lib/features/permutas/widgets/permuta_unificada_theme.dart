import 'package:flutter/material.dart';

/// Paleta alinhada ao Dashboard v3 — preto, azul e cinza sóbrios.
abstract final class PermutaUnificadaTheme {
  static const Color bgDeep = Color(0xFF0F1117);
  static const Color bgPanel = Color(0xFF1C1F28);
  static const Color bgGlass = Color(0xFF242830);
  static const Color border = Color(0xFF2A2D36);
  static const Color heroBlue = Color(0xFF1565C0);
  static const Color accent = Color(0xFF4A90D9);
  static const Color accentBlue = accent;
  static const Color accentBlueDeep = heroBlue;
  static const Color accentChain = Color(0xFF78909C);
  static const Color accentMutedGreen = Color(0xFF66BB6A);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0x8FFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Aliases para compatibilidade com widgets existentes
  static const Color accentPurple = accent;
  static const Color accentGreen = accentMutedGreen;
  static const Color accentAmber = accentChain;

  static TextStyle titleStyle([double size = 18]) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle monoStyle([double size = 12, Color? color]) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? textSecondary,
        height: 1.35,
      );

  static BoxDecoration panelDecoration({Color? borderColor}) => BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? border),
      );

  static BoxDecoration glassCard({Color accent = accentBlue}) => BoxDecoration(
        color: bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      );

  static ThemeData screenTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: heroBlue,
        surface: bgPanel,
      ),
    );
  }
}
