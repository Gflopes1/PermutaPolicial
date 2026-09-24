import '../models/user_profile.dart';

/// Resolve se o usuário tem acesso admin (embaixador ou moderador global).
class AdminAccess {
  AdminAccess._();

  static bool isAdmin(UserProfile? user) => user?.isAdmin ?? false;

  /// Prefere perfil com flag admin (Auth vs Dashboard podem estar dessincronizados).
  static UserProfile? resolveProfile({
    UserProfile? authUser,
    UserProfile? dashboardUser,
  }) {
    if (isAdmin(authUser)) return authUser;
    if (isAdmin(dashboardUser)) return dashboardUser;
    return authUser ?? dashboardUser;
  }

  static bool hasAdminAccess({
    UserProfile? authUser,
    UserProfile? dashboardUser,
  }) {
    return isAdmin(authUser) || isAdmin(dashboardUser);
  }
}
