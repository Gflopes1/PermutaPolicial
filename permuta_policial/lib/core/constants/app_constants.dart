// /lib/core/constants/app_constants.dart

/// Constantes da aplicação para breakpoints, espaçamentos e configurações
class AppConstants {
  AppConstants._(); // Construtor privado para evitar instanciação

  // ==========================================================
  // BREAKPOINTS PARA RESPONSIVIDADE
  // ==========================================================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // ==========================================================
  // ESPAÇAMENTOS PADRÃO
  // ==========================================================
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ==========================================================
  // DURAÇÕES DE ANIMAÇÃO
  // ==========================================================
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // ==========================================================
  // CONFIGURAÇÕES DE UI
  // ==========================================================
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputBorderRadius = 12.0;

  // ==========================================================
  // LARGURAS MÁXIMAS
  // ==========================================================
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 500.0;
  static const double sidebarWidth = 380.0;

  // ==========================================================
  // CONFIGURAÇÕES DE TIMEOUT
  // ==========================================================
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration snackBarDurationLong = Duration(seconds: 6);
}

