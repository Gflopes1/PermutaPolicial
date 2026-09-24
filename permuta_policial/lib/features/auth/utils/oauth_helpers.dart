import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/config/app_config.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/core/services/analytics_service.dart';
import 'package:permuta_policial/core/services/google_sign_in_service.dart';
import 'package:permuta_policial/core/utils/pwa_utils.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';

/// Helpers compartilhados de OAuth (Google / Microsoft) e mensagens.
class OAuthHelpers {
  OAuthHelpers._();

  static void showMessage(BuildContext context, String message, {bool isSuccess = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      isSuccess ? AppStyles.successSnackBar(message) : AppStyles.errorSnackBar(message),
    );
  }

  /// Resolve mensagem OAuth a partir dos query params (?error= & ?message=).
  /// Prioriza `message` legível do backend; evita exibir códigos crus ao usuário.
  static String? resolveOAuthError(Uri uri) {
    const knownCodes = {
      'oauth_failed': 'Falha na autenticação. Tente novamente.',
      'microsoft_oauth_failed': 'Falha no login com Microsoft. Tente novamente.',
      'microsoft_oauth_error': 'Erro retornado pela Microsoft. Tente outra conta.',
      'microsoft_auth_error': 'Erro ao validar login Microsoft. Tente novamente.',
      'microsoft_no_user': 'Conta Microsoft não autorizada ou não encontrada.',
      'microsoft_callback_invalid': 'Retorno inválido da Microsoft. Tente novamente.',
      'OAUTH_CODE_INVALID': 'Sessão OAuth expirada. Inicie o login novamente.',
      'token_missing': 'Token não encontrado. Tente novamente.',
    };

    final rawMessage = uri.queryParameters['message'];
    if (rawMessage != null && rawMessage.isNotEmpty) {
      final decoded = Uri.decodeComponent(rawMessage).trim();
      if (decoded.isNotEmpty) {
        return decoded.length <= 200 ? decoded : '${decoded.substring(0, 200)}…';
      }
    }

    final code = uri.queryParameters['error'];
    if (code == null || code.isEmpty) return null;
    if (knownCodes.containsKey(code)) return knownCodes[code];

    // Compatível com fluxos legados que colocam texto legível em ?error=
    final decodedCode = Uri.decodeComponent(code).trim();
    if (decodedCode.contains(' ') || decodedCode.length > 24) {
      return decodedCode.length <= 200 ? decodedCode : '${decodedCode.substring(0, 200)}…';
    }
    return 'Erro de autenticação. Tente novamente.';
  }

  static Future<void> launchExternal(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (context.mounted) showMessage(context, 'Não foi possível abrir o link.');
    }
  }

  static Future<void> openEmailApp(BuildContext context, {String? to}) async {
    final uri = Uri(scheme: 'mailto', path: to ?? '');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showMessage(context, 'Não foi possível abrir o app de email.');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Não foi possível abrir o app de email.');
      }
    }
  }

  static String? _normalizeReferralCode(String? referralCode) {
    final code = referralCode?.trim().toUpperCase();
    if (code == null || code.length < 3) return null;
    return code;
  }

  static String _buildOAuthQuery(Map<String, String> params) {
    if (params.isEmpty) return '';
    return params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  static Future<void> loginWithGoogle(
    BuildContext context, {
    String? referralCode,
  }) async {
    final ref = _normalizeReferralCode(referralCode);

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent('oauth_login_attempt', metadata: {
        'provider': 'google',
        if (ref != null) 'referral_code': ref,
      });
    } catch (_) {}

    if (!kIsWeb && GoogleSignInService.instance.isAvailable) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.loginWithGoogleNative(referralCode: ref);
      if (!success && context.mounted && auth.errorMessage != null) {
        showMessage(context, auth.errorMessage!);
      }
      return;
    }

    if (!kIsWeb && AppConfig.googleServerClientId == null) {
      if (context.mounted) {
        showMessage(
          context,
          'Login Google no app requer configuração de release. Use e-mail/senha ou atualize o app.',
        );
      }
      return;
    }

    final baseUrl = Provider.of<ApiClient>(context, listen: false).baseUrl;
    final params = <String, String>{};
    if (kIsWeb) {
      try {
        params['origin'] = Uri.base.origin;
      } catch (_) {}
    } else {
      params['platform'] = 'mobile';
    }
    if (ref != null) params['ref'] = ref;

    final query = _buildOAuthQuery(params);
    final googleAuthUrl = Uri.parse(
      query.isEmpty ? '$baseUrl/api/auth/google' : '$baseUrl/api/auth/google?$query',
    );

    final launched = kIsWeb
        ? await launchUrl(googleAuthUrl, webOnlyWindowName: '_self')
        : await launchUrl(googleAuthUrl, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      showMessage(context, 'Não foi possível iniciar o login com Google.');
    }
  }

  static Future<void> loginWithMicrosoft(
    BuildContext context, {
    String? idFuncional,
    int? editalId,
    String? returnTo,
    String? referralCode,
  }) async {
    final ref = _normalizeReferralCode(referralCode);

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent('oauth_login_attempt', metadata: {
        'provider': 'microsoft',
        if (ref != null) 'referral_code': ref,
      });
    } catch (_) {}

    final baseUrl = Provider.of<ApiClient>(context, listen: false).baseUrl;
    final params = <String, String>{};
    if (kIsWeb) {
      try {
        params['origin'] = Uri.base.origin;
        if (isPWA()) params['platform'] = 'pwa';
      } catch (_) {}
    } else {
      params['platform'] = 'mobile';
    }
    if (idFuncional != null && idFuncional.trim().isNotEmpty) {
      params['id_funcional'] = idFuncional.trim();
    }
    if (editalId != null) {
      params['edital_id'] = editalId.toString();
    }
    if (returnTo != null && returnTo.startsWith('/')) {
      params['return_to'] = returnTo;
    }
    if (ref != null) params['ref'] = ref;

    final query = _buildOAuthQuery(params);
    final microsoftAuthUrl = Uri.parse(
      query.isEmpty ? '$baseUrl/api/auth/microsoft' : '$baseUrl/api/auth/microsoft?$query',
    );

    final launched = kIsWeb
        ? await launchUrl(microsoftAuthUrl, webOnlyWindowName: '_self')
        : await launchUrl(microsoftAuthUrl, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      showMessage(context, 'Não foi possível iniciar o login com Microsoft.');
    }
  }
}
