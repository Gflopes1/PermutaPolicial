import '../models/user_profile.dart';

/// Perfil completo = lotação (unidade ou município) + posto/graduação.
bool isProfileIncomplete(UserProfile? user) {
  if (user == null) return true;
  if (user.unidadeAtualNome == null && user.municipioAtualNome == null) return true;
  if (user.postoGraduacaoId == null) return true;
  return false;
}