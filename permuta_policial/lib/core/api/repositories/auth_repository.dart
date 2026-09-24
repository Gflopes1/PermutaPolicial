// /lib/core/api/repositories/auth_repository.dart

import '../api_client.dart';
import '../../services/storage_service.dart';
import '../../models/user_profile.dart'; // Importamos o modelo de usuário

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  /// Tenta fazer login com email e senha.
  /// Se for bem-sucedido, salva o token e retorna um UserProfile.
  /// Se falhar, o ApiClient lançará uma ApiException.
  Future<UserProfile> login(String email, String password) async {
    final payload = {
      'email': email,
      'senha': password,
    };

    final responseData = await _apiClient.post('/api/auth/login', payload);

    final token = responseData['token'] as String?;
    final userData = responseData['utilizador'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      throw Exception('Resposta de login inválida do servidor.');
    }

    await _storageService.saveToken(token);

    // Retorna um objeto UserProfile completo
    return UserProfile.fromJson(userData);
  }

  /// Registra um novo usuário.
  /// Retorna a mensagem de sucesso do servidor.
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final responseData = await _apiClient.post(
      '/api/auth/registrar',
      userData,
      requireAuth: false,
    );
    return responseData;
  }

  /// Confirma o email do usuário com o código de 6 dígitos.
  /// Retorna a mensagem de sucesso do servidor.
  Future<Map<String, dynamic>> confirmEmail(
    String email,
    String code, {
    String? referralCode,
  }) async {
    final payload = {
      'email': email,
      'codigo': code,
      if (referralCode != null && referralCode.trim().length >= 3)
        'referral_code': referralCode.trim().toUpperCase(),
    };
    final responseData = await _apiClient.post(
      '/api/auth/confirmar-email',
      payload,
      requireAuth: false,
    );
    return responseData;
  }

  /// Solicita um código de recuperação de senha.
  /// Retorna a mensagem de confirmação do servidor.
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final payload = {'email': email};
    final responseData = await _apiClient.post('/api/auth/solicitar-recuperacao', payload);
    return responseData;
  }

  /// Valida o código de recuperação e retorna um token temporário.
  /// Retorna um objeto contendo a mensagem e o 'token_recuperacao'.
  Future<Map<String, dynamic>> validateResetCode(String email, String code) async {
    final payload = {
      'email': email,
      'codigo': code,
    };
    final responseData = await _apiClient.post('/api/auth/validar-codigo', payload);
    return responseData;
  }

  /// Redefine a senha usando o token temporário e a nova senha.
  /// Retorna a mensagem de sucesso do servidor.
  Future<Map<String, dynamic>> resetPassword(String tempToken, String newPassword) async {
    final payload = {
      'token_recuperacao': tempToken,
      'nova_senha': newPassword,
    };
    final responseData = await _apiClient.post('/api/auth/redefinir-senha', payload);
    return responseData;
  }

  /// Login Google nativo (APK) via ID Token.
  Future<Map<String, dynamic>> loginWithGoogleIdToken(
    String idToken, {
    String? referralCode,
  }) async {
    final payload = <String, dynamic>{'id_token': idToken};
    if (referralCode != null && referralCode.trim().length >= 3) {
      payload['referral_code'] = referralCode.trim().toUpperCase();
    }
    final responseData = await _apiClient.post('/api/auth/google/native', payload);

    final data = responseData is Map && responseData.containsKey('data')
        ? responseData['data'] as Map<String, dynamic>
        : responseData as Map<String, dynamic>;

    final token = data['token'] as String?;
    if (token == null) {
      throw Exception('Resposta de login Google inválida.');
    }

    await _storageService.saveToken(token);
    return data;
  }

  /// Troca código OAuth de uso único por JWT (evita token na URL).
  Future<Map<String, dynamic>> exchangeOAuthCode(String code) async {
    final data = await _apiClient.post(
      '/api/auth/exchange-code',
      {'code': code},
      requireAuth: false,
    ) as Map<String, dynamic>;

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Resposta de exchange OAuth inválida.');
    }

    await _storageService.saveToken(token);
    return data;
  }

  /// Faz o logout do usuário, removendo o token do armazenamento.
  Future<void> logout() async {
    await _storageService.deleteToken();
  }
}