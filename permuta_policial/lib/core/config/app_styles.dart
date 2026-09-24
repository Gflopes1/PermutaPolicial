// /lib/core/config/app_styles.dart

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Classe centralizada com estilos padronizados do aplicativo
/// Baseado na SplashScreen e DashboardScreenV3
class AppStyles {
  // ========== ESPAÇAMENTOS PADRÃO ==========
  static const double spacingXS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ========== BORDAS E RAIO ==========
  static const double borderRadiusSM = 8.0;
  static const double borderRadiusMD = 12.0;
  static const double borderRadiusLG = 16.0;

  // ========== GRADIENTE PADRÃO ==========
  static BoxDecoration get defaultGradientDecoration => const BoxDecoration(
        gradient: AppTheme.defaultGradient,
      );

  static Widget defaultGradientContainer({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : null,
          decoration: defaultGradientDecoration,
          child: child,
        );
      },
    );
  }

  // ========== TIPOGRAFIA PADRÃO ==========
  
  /// Título principal (usado na SplashScreen)
  static TextStyle get titleLarge => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        letterSpacing: 1.2,
      );

  /// Título médio
  static TextStyle get titleMedium => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        letterSpacing: 0.5,
      );

  /// Título pequeno
  static TextStyle get titleSmall => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      );

  /// Texto de corpo grande
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppTheme.textPrimary,
        height: 1.5,
      );

  /// Texto de corpo médio
  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppTheme.textPrimary,
        height: 1.5,
      );

  /// Texto de corpo pequeno (subtítulos)
  static TextStyle get bodySmall => const TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondary,
        height: 1.5,
      );

  /// Texto secundário pequeno
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        color: AppTheme.textSecondary.withAlpha(179),
        letterSpacing: 0.5,
      );

  // ========== BOTÕES PADRÃO ==========

  /// Botão primário elevado
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMD),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  /// Botão outlined (usado na LandingScreen)
  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMD),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  /// Botão de texto
  static ButtonStyle get textButton => TextButton.styleFrom(
        foregroundColor: AppTheme.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  /// Botão de perigo (vermelho)
  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.error,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMD),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      );

  // ========== CARDS PADRÃO ==========

  /// Card padrão com estilo do Dashboard
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      color: AppTheme.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMD),
      ),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  // ========== INPUTS PADRÃO ==========

  /// Container de input com estilo padronizado
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(borderRadiusMD),
        border: Border.all(color: AppTheme.inputBorder),
      );

  // ========== WIDGETS AUXILIARES ==========

  /// SizedBox com espaçamento padrão pequeno (16px)
  static const SizedBox spacingSmall = SizedBox(height: spacingMD);

  /// SizedBox com espaçamento padrão médio (24px)
  static const SizedBox spacingMedium = SizedBox(height: spacingLG);

  /// SizedBox com espaçamento padrão grande
  static const SizedBox spacingLarge = SizedBox(height: spacingXL);

  /// CircularProgressIndicator padronizado
  static const CircularProgressIndicator defaultLoader = CircularProgressIndicator(
    strokeWidth: 3,
    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
  );

  /// Logo do aplicativo com tamanho padrão
  static Widget logo({double size = 120}) {
    return Hero(
      tag: 'app_logo',
      child: Image.asset(
        'assets/images/logo_tatico.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  // ========== CONTAINER COM GRADIENTE ==========

  /// Scaffold com gradiente padrão
  static Widget gradientScaffold({
    bool resizeToAvoidBottomInset = false,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: defaultGradientContainer(child: body),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  // ========== SNACKBAR PADRÃO ==========

  /// SnackBar de sucesso
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSM),
      ),
    );
  }

  /// SnackBar de erro
  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSM),
      ),
    );
  }
}

