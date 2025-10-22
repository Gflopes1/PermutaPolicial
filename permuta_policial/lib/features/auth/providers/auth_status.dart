// /lib/features/auth/providers/auth_status.dart

enum AuthStatus {
  unknown,          // Estado inicial, ainda não verificado
  authenticating,   // Processando login/registro
  authenticated,    // Usuário logado com sucesso
  unauthenticated,  // Usuário deslogado ou falha no login
}