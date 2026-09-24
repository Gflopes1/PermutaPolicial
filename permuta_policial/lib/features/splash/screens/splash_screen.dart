// /lib/features/splash/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/platform_utils.dart';

import 'package:go_router/go_router.dart';
import '../../../core/utils/profile_completion.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/version_service.dart';
import '../../../core/services/visitor_prefs.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_status.dart';

void _splashLog(String message) {
  if (AppLogger.isDevLoggingEnabled) {
    debugPrint('[Splash] $message');
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  bool _showSpinner = false;
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const Duration _spinnerDelay = Duration(milliseconds: 600);
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _spinnerTimer = Timer(_spinnerDelay, () {
      if (mounted && !_hasNavigated) {
        setState(() => _showSpinner = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextRoute();
    });
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _trackSplashAnalytics() {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      unawaited(analyticsService.trackPageView('/splash'));
      unawaited(analyticsService.trackEvent('splash_screen_viewed'));
    } catch (_) {}
  }

  Future<void> _checkVersionInBackground() async {
    try {
      final versionService = Provider.of<VersionService>(context, listen: false);
      final hasUpdated = await versionService.hasAppUpdated();
      if (hasUpdated && kIsWeb) {
        _splashLog('Nova versão detectada. Cache busting ativo.');
      }
    } catch (e) {
      _splashLog('Erro ao verificar versão (não crítico): $e');
    }
  }

  Future<void> _decideNextRoute() async {
    if (_hasNavigated || !mounted) return;

    try {
      _trackSplashAnalytics();
      unawaited(_checkVersionInBackground());

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String currentUrl = '';
      String pathname = '';
      String searchParams = '';

      if (kIsWeb) {
        currentUrl = getUrl();
        pathname = getPathname();
        searchParams = getSearch();
      }

      final currentRoute = GoRouterState.of(context).uri.path;
      final currentRouteQuery = GoRouterState.of(context).uri.queryParameters;

      final hasCallbackPathWeb =
          kIsWeb && (pathname.contains('/auth/callback') || currentUrl.contains('/auth/callback'));
      final hasCallbackPathRouter =
          currentRoute == '/auth/callback' || currentRoute.contains('/auth/callback');

      if (hasCallbackPathWeb || hasCallbackPathRouter) {
        _splashLog('CALLBACK DETECTADO — navegando para AuthCallbackScreen.');
        _hasNavigated = true;
        if (!hasCallbackPathRouter) {
          if (kIsWeb && currentUrl.contains('/auth/callback')) {
            try {
              final uri = Uri.parse(currentUrl);
              final callbackPath =
                  uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
              context.go(callbackPath);
            } catch (_) {
              context.go(AppRoutes.authCallback);
            }
          } else {
            context.go(AppRoutes.authCallback);
          }
        }
        return;
      }

      final hasErrorInUrl =
          kIsWeb && (currentUrl.contains('error=') || searchParams.contains('error='));
      final hasErrorInRoute = currentRouteQuery.containsKey('error');

      // Código OAuth na raiz (redirect legado/incorreto) → normaliza para /auth/callback
      final oauthCode = currentRouteQuery['code'] ??
          (kIsWeb ? Uri.tryParse(currentUrl)?.queryParameters['code'] : null);
      if (oauthCode != null && oauthCode.isNotEmpty) {
        _hasNavigated = true;
        final next = currentRouteQuery['next'] ??
            Uri.tryParse(currentUrl)?.queryParameters['next'];
        final completar = currentRouteQuery['completar'] == 'true' ||
            Uri.tryParse(currentUrl)?.queryParameters['completar'] == 'true';
        final buffer = StringBuffer('${AppRoutes.authCallback}?code=${Uri.encodeComponent(oauthCode)}');
        if (completar) buffer.write('&completar=true');
        if (next != null && next.startsWith('/')) {
          buffer.write('&next=${Uri.encodeComponent(next)}');
        }
        context.go(buffer.toString());
        return;
      }

      if (hasErrorInUrl || hasErrorInRoute) {
        _hasNavigated = true;
        final uri = kIsWeb && currentUrl.isNotEmpty
            ? Uri.tryParse(currentUrl)
            : GoRouterState.of(context).uri;
        final error = uri?.queryParameters['error'];
        final message = uri?.queryParameters['message'];
        if (error != null && error.isNotEmpty) {
          final q = message != null && message.isNotEmpty
              ? '?error=${Uri.encodeComponent(error)}&message=${Uri.encodeComponent(message)}'
              : '?error=${Uri.encodeComponent(error)}';
          context.go('${AppRoutes.auth}$q');
        } else {
          context.go(AppRoutes.auth);
        }
        if (kIsWeb && uri != null) {
          replaceHistoryState(uri.replace(queryParameters: {}).toString());
        }
        return;
      }

      // Link de indicação no path (/r/CODIGO) — não passar pelo auto-login
      final referralPath = pathname.isNotEmpty ? pathname : currentRoute;
      final referralMatch = RegExp(r'^/r/([A-Za-z0-9]+)/?$').firstMatch(referralPath);
      if (referralMatch != null) {
        _hasNavigated = true;
        final code = referralMatch.group(1)!;
        context.go('/r/$code');
        return;
      }

      try {
        await authProvider.tryAutoLogin().timeout(
          _timeoutDuration,
          onTimeout: () {
            throw TimeoutException('Login automático demorou muito', _timeoutDuration);
          },
        );
      } catch (e) {
        _splashLog('Auto login falhou (esperado sem token): $e');
      }

      if (!mounted || _hasNavigated) return;

      final routeAfterAutoLogin = GoRouterState.of(context).uri.path;
      final urlAfterAutoLogin = kIsWeb ? getUrl() : '';
      if ((kIsWeb && urlAfterAutoLogin.contains('/auth/callback')) ||
          routeAfterAutoLogin.contains('/auth/callback')) {
        _hasNavigated = true;
        if (!routeAfterAutoLogin.contains('/auth/callback')) {
          context.go(AppRoutes.authCallback);
        }
        return;
      }

      final wantsVisitorMap = currentRoute == AppRoutes.mapaVisitante ||
          (currentRoute == AppRoutes.mapa &&
              (currentRouteQuery['visitor'] == 'true' ||
                  currentRouteQuery['visitor'] == '1')) ||
          (kIsWeb &&
              (pathname == AppRoutes.mapaVisitante ||
                  (pathname == AppRoutes.mapa &&
                      (searchParams.contains('visitor=true') ||
                          searchParams.contains('visitor=1')))));

      if (wantsVisitorMap && authProvider.status != AuthStatus.authenticated) {
        await VisitorPrefs.setVisitorMode(true);
        _hasNavigated = true;
        context.go(AppRoutes.mapaVisitante);
        return;
      }

      if (authProvider.status == AuthStatus.authenticated) {
        await VisitorPrefs.clear();
        _hasNavigated = true;
        final dest = isProfileIncomplete(authProvider.user)
            ? AppRoutes.completarPerfil
            : AppRoutes.dashboard;
        context.go(dest);
        return;
      }

      // Preferência local de visitante: não joga de volta no login
      final visitorPref = await VisitorPrefs.isVisitorMode();
      if (visitorPref) {
        _hasNavigated = true;
        context.go(AppRoutes.mapaVisitante);
        return;
      }

      _hasNavigated = true;
      context.go(AppRoutes.landing);
    } on TimeoutException catch (_) {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      final visitorPref = await VisitorPrefs.isVisitorMode();
      context.go(visitorPref ? AppRoutes.mapaVisitante : AppRoutes.landing);
    } catch (e, stackTrace) {
      _splashLog('Erro na SplashScreen: $e\n$stackTrace');
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      context.go(AppRoutes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStyles.gradientScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppStyles.logo(size: 120),
            AppStyles.spacingLarge,
            Text('Permuta Policial', style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingXXL),
            AnimatedOpacity(
              opacity: _showSpinner ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.primaryLight.withAlpha(220),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
