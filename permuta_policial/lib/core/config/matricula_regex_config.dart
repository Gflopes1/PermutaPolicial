// Regex de matrícula/ID funcional por sigla da força — ajuste conforme cada corporação.

class MatriculaRegexConfig {
  static const Map<String, String> patternsByForca = {
    'default': r'^[\dA-Za-z.\-/]{4,20}$',
    'PMESP': r'^\d{6,8}$',
    'PMERJ': r'^\d{5,7}$',
    'PMSP': r'^\d{6,8}$',
    'PRF': r'^\d{5,7}$',
    'PF': r'^\d{5,7}$',
    'PCSP': r'^\d{5,8}$',
    'BMRS': r'^\d{5,8}$',
  };

  static RegExp getRegex(String? forcaSigla) {
    final sigla = (forcaSigla ?? '').trim().toUpperCase();
    final pattern = patternsByForca[sigla] ?? patternsByForca['default']!;
    return RegExp(pattern);
  }

  static bool isValid(String? matricula, String? forcaSigla) {
    final value = (matricula ?? '').trim();
    if (value.isEmpty) return false;
    return getRegex(forcaSigla).hasMatch(value);
  }
}
