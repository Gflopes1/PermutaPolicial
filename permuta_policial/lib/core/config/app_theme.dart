// /lib/core/config/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Cores Principal
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFCF6679);

  // Cores de Fundo
  static const Color background = Color(0xFF181A20); // Fundo principal (quase preto)
  static const Color card = Color(0xFF23272F);       // Fundo de cards e superfícies
  
  // Cores de Componentes de Formulário
  static const Color inputFill = Color(0xFF23272F);
  static const Color inputBorder = Colors.white24;

  // Cores de Texto
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;


  /// TEMA DARK COMPLETO
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    cardColor: card,
    
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: card,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      // A linha 'onBackground: textPrimary,' foi removida daqui para resolver o aviso.
      onError: Colors.black,
    ),

    // Tema para campos de texto
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
    ),

    // Tema para botões elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Tema para TabBar
    tabBarTheme: const TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: textSecondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2.0),
      ),
    ),
  );
}