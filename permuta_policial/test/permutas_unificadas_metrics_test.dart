import 'package:flutter_test/flutter_test.dart';
import 'package:permuta_policial/core/models/match_results.dart';
import 'package:permuta_policial/core/models/smart_match_results.dart';
import 'package:permuta_policial/features/permutas/utils/permutas_unificadas_utils.dart';

Match _m(int id) => Match(id: id, nome: 'P$id', forcaSigla: 'PM');

FullMatchResults _legacyInteressados(List<int> ids) {
  return FullMatchResults(
    configuracao: Configuracao(
      aceitaPermutaInterestadual: false,
      tipoPermuta: 'PM',
      forcaSigla: 'PMERJ',
      regraPermuta: 'teste',
    ),
    interessados: ids.map(_m).toList(),
    diretas: const [],
    triangulares: const [],
  );
}

SmartMatchResults _piInteressados(List<int> ids) {
  return SmartMatchResults(
    configuracao: Configuracao(
      aceitaPermutaInterestadual: false,
      tipoPermuta: 'PM',
      forcaSigla: 'PMERJ',
      regraPermuta: 'teste',
    ),
    diretas: const [],
    proximas: const [],
    interessados: ids.map((id) => SmartMatch(id: id, nome: 'PI$id', forcaSigla: 'PM')).toList(),
    triangulares: const [],
    ciclosN: const [],
    cache: SmartMatchCacheInfo(hit: true),
  );
}

void main() {
  test('regressão: legado 3 interessados vs unificado 14', () {
    final legacy = _legacyInteressados([1, 2, 3]);
    final pi = _piInteressados(List.generate(11, (i) => 100 + i));
    final piIds = PermutasUnificadasUtils.piPolicialIds(pi);

    expect(legacy.interessados.length, 3);
    expect(
      PermutasUnificadasUtils.countInteressadosMatches(legacy, pi, piIds),
      14,
    );

    final metricas = PermutasUnificadasUtils.buildUnifiedMetrics(legacy, pi);
    expect(metricas.interestedCandidates, 14);
    expect(metricas.meta.algorithmVersion, 'unificado_v1');
  });
}
