// /lib/features/auth/screens/auth_callback_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/repositories/auth_repository.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/visitor_prefs.dart';
import '../providers/auth_provider.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String? token;
  final String? code;
  final bool completarPerfil;
  final String? nextPath;

  const AuthCallbackScreen({
    super.key,
    this.token,
    this.code,
    this.completarPerfil = false,
    this.nextPath,
  });

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _isProcessing = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isProcessing) {
        _handleAuthCallback();
      }
    });
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/auth/callback');
      await analyticsService.trackEvent('auth_callback_viewed', metadata: {
        'completar_perfil': widget.completarPerfil.toString(),
        'via_code': (widget.code != null).toString(),
      });
    } catch (e) {
      debugPrint('Erro ao rastrear analytics no callback: $e');
    }
  }

  Future<String?> _resolveToken() async {
    final code = widget.code?.trim();
    if (code != null && code.isNotEmpty) {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final data = await authRepository.exchangeOAuthCode(code);
      return data['token'] as String?;
    }

    final legacyToken = widget.token?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) {
      final storage = Provider.of<StorageService>(context, listen: false);
      await storage.saveToken(legacyToken);
      return legacyToken;
    }

    return null;
  }

  Future<void> _handleAuthCallback() async {
    if (_isProcessing) return;
    _isProcessing = true;
    await _trackPageView();

    if (!mounted) {
      _isProcessing = false;
      return;
    }

    try {
      final token = await _resolveToken();
      if (token == null || token.isEmpty) {
        try {
          final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
          await analyticsService.trackEvent('auth_callback_error', metadata: {
            'error': 'token_missing',
          });
        } catch (_) {}

        if (mounted) {
          context.go(
            '${AppRoutes.auth}?error=${Uri.encodeComponent('Código de autenticação inválido ou expirado. Tente novamente.')}',
          );
        }
        _isProcessing = false;
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await _updateAuthStateWithRetry(authProvider, token);
      if (!mounted) {
        _isProcessing = false;
        return;
      }

      if (success) {
        try {
          final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
          await analyticsService.trackEvent('auth_callback_success');
        } catch (_) {}

        await VisitorPrefs.clear();

        final next = widget.nextPath;
        if (next != null && next.startsWith('/') && !next.startsWith('//')) {
          if (mounted) context.go(next);
          return;
        }

        final perfilIncompleto = authProvider.user?.unidadeAtualNome == null &&
            authProvider.user?.municipioAtualNome == null;

        if (perfilIncompleto || widget.completarPerfil) {
          if (mounted) context.go(AppRoutes.completarPerfil);
        } else {
          if (mounted) context.go(AppRoutes.dashboard);
        }
      } else {
        if (mounted) {
          final errorMsg = authProvider.errorMessage ?? 'Falha ao autenticar.';
          context.go('${AppRoutes.auth}?error=${Uri.encodeComponent(errorMsg)}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('AuthCallbackScreen erro: $e\n$stackTrace');
      if (mounted) {
        context.go(
          '${AppRoutes.auth}?error=${Uri.encodeComponent('Erro ao processar autenticação.')}',
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _updateAuthStateWithRetry(AuthProvider authProvider, String token) async {
    while (_retryCount < _maxRetries) {
      try {
        final success = await authProvider.updateAuthenticationState(token: token);
        if (success) {
          _retryCount = 0;
          return true;
        }
        if (_retryCount < _maxRetries - 1) {
          _retryCount++;
          if (mounted) setState(() {});
          await Future.delayed(_retryDelay);
        } else {
          return false;
        }
      } catch (e) {
        if (_retryCount < _maxRetries - 1) {
          _retryCount++;
          if (mounted) setState(() {});
          await Future.delayed(_retryDelay);
        } else {
          rethrow;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppStyles.gradientScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppStyles.logo(size: 100),
            AppStyles.spacingLarge,
            Shimmer.fromColors(
              baseColor: Colors.white24,
              highlightColor: Colors.white70,
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 140,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            AppStyles.spacingLarge,
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryLight.withAlpha(230)),
              ),
            ),
            if (_retryCount > 0) ...[
              AppStyles.spacingSmall,
              Text(
                'Tentativa ${_retryCount + 1} de $_maxRetries',
                style: AppStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
