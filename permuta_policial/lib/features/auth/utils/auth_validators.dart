/// Validadores e utilitários de senha/email para o fluxo de auth.
class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  /// Regra mínima: 8 caracteres. Complexidade é recomendação, não bloqueio.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != password) return 'As senhas não coincidem';
    return null;
  }

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label é obrigatório';
    return null;
  }

  static String? otpCode(String? value) {
    if ((value?.length ?? 0) != 6) return 'Código inválido';
    return null;
  }

  static bool isGovBrEmail(String email) {
    final dominio = email.trim().toLowerCase().split('@').last;
    return dominio == 'gov.br' || dominio.endsWith('.gov.br');
  }
}

/// Força visual da senha (0–4). Não bloqueia cadastro.
enum PasswordStrength { empty, weak, fair, good, strong }

class PasswordStrengthHelper {
  PasswordStrengthHelper._();

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.fair;
    if (score == 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  static String label(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.fair:
        return 'Razoável';
      case PasswordStrength.good:
        return 'Boa';
      case PasswordStrength.strong:
        return 'Forte';
    }
  }

  static double progress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}
