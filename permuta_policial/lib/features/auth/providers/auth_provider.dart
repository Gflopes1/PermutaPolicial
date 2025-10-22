// /lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/auth_repository.dart';
import '../../../core/api/repositories/policiais_repository.dart';
import '../../../core/models/user_profile.dart';
import 'auth_status.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final PoliciaisRepository _policiaisRepository;

  AuthProvider(this._authRepository, this._policiaisRepository);

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> tryAutoLogin() async {
    try {
      final userProfile = await _policiaisRepository.getMyProfile();
      _user = userProfile;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      await _authRepository.logout(); 
      notifyListeners();
      return false;
    }
  }

  Future<String?> register(Map<String, dynamic> userData) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authRepository.register(userData);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return response['message'];
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmEmail(String email, String code) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.confirmEmail(email, code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}