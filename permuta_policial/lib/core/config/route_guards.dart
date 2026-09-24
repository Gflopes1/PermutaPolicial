// /lib/core/config/route_guards.dart

import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_status.dart';
import '../utils/profile_completion.dart';

/// Rotas acessíveis sem autenticação.
const _publicPaths = {
  '/',
  '/landing',
  '/auth',
  '/auth/register',
  '/auth/confirm-email',
  '/auth/forgot-password',
  '/auth/callback',
  '/mapa/visitante',
};

bool _isReferralLandingRoute(String path) {
  return RegExp(r'^/r/[A-Za-z0-9]+/?$').hasMatch(path);
}

const _completarPerfilPath = '/completar-perfil';
bool _isVisitorMapaRoute(GoRouterState state) {
  final path = state.uri.path;
  if (path == '/mapa/visitante') return true;
  final visitor = state.uri.queryParameters['visitor'];
  return path == '/mapa' && (visitor == 'true' || visitor == '1');
}

bool _isEditalConsultaRoute(GoRouterState state) {
  final path = state.uri.path;
  return RegExp(r'^/editais/\d+/consulta/?$').hasMatch(path) ||
      RegExp(r'^/edital/\d+/?$').hasMatch(path);
}

bool _isEditalRoute(String path) {
  return path == '/editais' || path.startsWith('/editais/');
}

bool _isPublicRoute(GoRouterState state) {
  final path = state.uri.path;
  if (_publicPaths.contains(path)) return true;
  if (_isReferralLandingRoute(path)) return true;
  if (_isVisitorMapaRoute(state)) return true;
  if (_isEditalConsultaRoute(state)) return true;
  return false;
}

bool _isAdminRoute(String path) {
  return path == '/admin' || path.startsWith('/admin/');
}

bool _hasAdminAccess(AuthProvider auth) {
  final user = auth.user;
  if (user == null) return false;
  return user.isEmbaixador || user.isModerator;
}

/// Redirect global do GoRouter com base no estado de autenticação.
String? authRedirect(AuthProvider auth, GoRouterState state) {
  final path = state.uri.path;

  if (auth.status == AuthStatus.unknown) {
    if (_isPublicRoute(state)) return null;
    return '/';
  }

  if (!auth.isAuthenticated && !_isPublicRoute(state)) {
    return '/auth';
  }

  if (auth.isAuthenticated) {
    final incomplete = isProfileIncomplete(auth.user);

    // Link de indicação: usuário logado pode vincular indicador (ReferralLandingScreen)
    if (_isReferralLandingRoute(path)) {
      return null;
    }

    // Perfil incompleto: permite completar cadastro e rotas de edital (inscrição rápida).
    if (incomplete &&
        path != _completarPerfilPath &&
        !_isEditalRoute(path) &&
        !_isEditalConsultaRoute(state)) {
      return _completarPerfilPath;
    }

    // Perfil já completo: não fica preso em /completar-perfil.
    if (!incomplete && path == _completarPerfilPath) {
      return '/dashboard';
    }

    if (path == '/auth' ||
        path == '/auth/register' ||
        path == '/auth/confirm-email' ||
        path == '/auth/forgot-password' ||
        path == '/landing') {
      return incomplete ? _completarPerfilPath : '/dashboard';
    }
  }

  if (_isAdminRoute(path) && !_hasAdminAccess(auth)) {
    return '/dashboard';
  }

  return null;
}

/// Guard para uso em rotas individuais (fallback).
class AuthGuard {
  static String? redirect(AuthProvider auth, GoRouterState state) {
    if (auth.status == AuthStatus.unknown) {
      return _isPublicRoute(state) ? null : '/';
    }
    if (!auth.isAuthenticated && !_isPublicRoute(state)) return '/auth';
    return null;
  }
}

class AdminGuard {
  static String? redirect(AuthProvider auth, GoRouterState state) {
    if (auth.status == AuthStatus.unknown) {
      return _isPublicRoute(state) ? null : '/';
    }
    if (!auth.isAuthenticated) return '/auth';
    if (!_hasAdminAccess(auth)) return '/dashboard';
    return null;
  }
}
