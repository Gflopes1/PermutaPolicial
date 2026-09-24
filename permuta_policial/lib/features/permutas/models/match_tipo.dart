enum MatchTipo {
  direta,
  proxima,
  ciclo,
  triangular,
  interessado;

  String get label {
    switch (this) {
      case MatchTipo.direta:
        return 'DIRETA';
      case MatchTipo.proxima:
        return 'PRÓXIMA';
      case MatchTipo.ciclo:
        return 'CICLO';
      case MatchTipo.triangular:
        return 'TRIANGULAR';
      case MatchTipo.interessado:
        return 'INTERESSADO';
    }
  }

  String get tipoPermutaApi {
    switch (this) {
      case MatchTipo.direta:
        return 'direta';
      case MatchTipo.proxima:
        return 'proxima';
      case MatchTipo.triangular:
        return 'triangular';
      case MatchTipo.interessado:
        return 'interessado';
      case MatchTipo.ciclo:
        return 'ciclo';
    }
  }
}
