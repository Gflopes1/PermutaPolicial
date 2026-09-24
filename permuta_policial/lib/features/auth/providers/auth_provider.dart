// /lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/auth_repository.dart';
import '../../../core/api/repositories/policiais_repository.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/storage_service.dart';
import 'auth_status.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final PoliciaisRepository _policiaisRepository;
  final AnalyticsService _analyticsService;
  final StorageService _storageService;
  final PushNotificationService? _pushService;

  AuthProvider(
    this._authRepository,
    this._policiaisRepository,
    this._analyticsService,
    this._storageService, [
    this._pushService,
  ]);

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;
  String? _errorMessage;
  DateTime? _lastProfileRefreshAt;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Chamado ao retornar do background (web/mobile). Revalida sessão sem bloquear a UI.
  Future<void> handleAppResume() async {
    if (_status == AuthStatus.authenticated) {
      final now = DateTime.now();
      final last = _lastProfileRefreshAt;
      // Evita refetch + rebuild de toda a árvore a cada troca de aba no navegador.
      if (last != null && now.difference(last) < const Duration(minutes: 2)) {
        return;
      }
      await refreshProfile();
      return;
    }

    if (_status == AuthStatus.unauthenticated) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await tryAutoLogin();
        } catch (e) {
          debugPrint('⚠️ AuthProvider.handleAppResume: $e');
        }
      }
    }
  }

  // Método para recarregar o perfil do usuário
  Future<void> refreshProfile() async {
    if (_status != AuthStatus.authenticated) {
      debugPrint("⚠️ AuthProvider.refreshProfile: Usuário não autenticado, pulando refresh");
      return;
    }
    
    try {
      debugPrint("🔄 AuthProvider: Recarregando perfil do usuário...");
      final userProfile = await _policiaisRepository.getMyProfile();
      _user = userProfile;
      _lastProfileRefreshAt = DateTime.now();
      debugPrint("✅ AuthProvider: Perfil recarregado com sucesso");
      debugPrint("   - isPremium: ${userProfile.isPremium}");
      debugPrint("   - subscription: ${userProfile.subscription}");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ AuthProvider: Erro ao recarregar perfil: $e");
      // Não altera o status se houver erro, apenas loga
    }
  }

Future<void> tryAutoLogin() async {
    try {
      debugPrint("🔍 AuthProvider: Tentando auto login...");
      
      // 1. Verifica se existe um token localmente antes de fazer a chamada na API
      final token = await _storageService.getToken();
      
      if (token == null || token.isEmpty) {
        debugPrint("ℹ️ AuthProvider: Nenhum token encontrado localmente, cancelando auto login.");
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return; // Sai do método antes de fazer a chamada que daria erro 401
      }

      // 2. Se tem token, aí sim tenta buscar o perfil do usuário
      final userProfile = await _policiaisRepository.getMyProfile();
      _user = userProfile;
      _status = AuthStatus.authenticated;
      
      await _afterSuccessfulAuth();
      debugPrint("✅ AuthProvider: Auto login bem-sucedido");
    } catch (e) {
      debugPrint("❌ AuthProvider: Auto login falhou: $e");
      _status = AuthStatus.unauthenticated;
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/policiais/me', method: 'GET');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.login(email, password);
      final fullProfile = await _policiaisRepository.getMyProfile();
      _user = fullProfile;
      _status = AuthStatus.authenticated;
      
      await _afterSuccessfulAuth();
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/login', method: 'POST');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // CORREÇÃO APLICADA AQUI
  Future<bool> updateAuthenticationState({String? token}) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      // Passa o token para o repositório
      final userProfile = await _policiaisRepository.getMyProfile(token: token);
      _user = userProfile;
      _status = AuthStatus.authenticated;
      
      await _afterSuccessfulAuth();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/policiais/me', method: 'GET');
      _status = AuthStatus.unauthenticated;
      // Só faz logout se for erro de autenticação
      if (ErrorHandler.requiresReauth(e)) {
        await _authRepository.logout();
      }
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(Map<String, dynamic> userData) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authRepository.register(userData);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return response;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao registrar. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/register', method: 'POST');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmEmail(
    String email,
    String code, {
    String? referralCode,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.confirmEmail(
        email,
        code,
        referralCode: referralCode,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao confirmar email. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/confirm-email', method: 'POST');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> requestPasswordReset(String email) async {
    _errorMessage = null;
    try {
      await _authRepository.requestPasswordReset(email);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao solicitar recuperação. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/request-password-reset', method: 'POST');
      notifyListeners();
      return false;
    }
  }
  
  Future<String?> validateResetCode(String email, String code) async {
    _errorMessage = null;
    try {
      final response = await _authRepository.validateResetCode(email, code);
      return response['token_recuperacao'];
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Código inválido. Verifique e tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/validate-reset-code', method: 'POST');
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword(String tempToken, String newPassword) async {
    _errorMessage = null;
    try {
      await _authRepository.resetPassword(tempToken, newPassword);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao redefinir senha. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/auth/reset-password', method: 'POST');
      notifyListeners();
      return false;
    }
  }

  /// Login Google nativo (APK) — retorna false se cancelado ou erro.
  Future<bool> loginWithGoogleNative({String? referralCode}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await GoogleSignInService.instance.signInAndGetIdToken();
      if (idToken == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      await _authRepository.loginWithGoogleIdToken(
        idToken,
        referralCode: referralCode,
      );
      final fullProfile = await _policiaisRepository.getMyProfile();
      _user = fullProfile;
      _status = AuthStatus.authenticated;
      await _afterSuccessfulAuth();
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = 'Erro ao entrar com Google. Tente novamente.';
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/auth/google/native',
        method: 'POST',
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _afterSuccessfulAuth() async {
    try {
      await _analyticsService.createOrUpdateSession();
    } catch (e) {
      debugPrint('Erro ao criar sessão de analytics: $e');
    }
    try {
      await _pushService?.registerTokenWithBackend();
    } catch (e) {
      debugPrint('Erro ao registrar push: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _pushService?.unregisterToken();
      await GoogleSignInService.instance.signOut();
    } catch (_) {}
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Chamado pelo ApiClient quando o token expira (401).
  Future<void> handleSessionExpired() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Sua sessão expirou. Por favor, faça login novamente.';
    notifyListeners();
  }
}