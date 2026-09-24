import '../../../core/models/intencao.dart';
import '../../../core/models/match_results.dart';
import '../../../core/models/permutas_canonical_metrics.dart';
import '../../../core/models/smart_match_results.dart';

/// Utilitários de deduplicação e diagnóstico para a tela unificada.
abstract final class PermutasUnificadasUtils {
  /// IDs de policiais presentes nos resultados da PI (prioridade na exibição).
  static Set<int> piPolicialIds(SmartMatchResults pi) {
    final ids = <int>{};
    for (final m in pi.diretas) {
      ids.add(m.id);
    }
    for (final m in pi.proximas) {
      ids.add(m.id);
    }
    for (final m in pi.interessados) {
      ids.add(m.id);
    }
    for (final t in pi.triangulares) {
      ids.add(t.policialB.id);
      ids.add(t.policialC.id);
    }
    for (final c in pi.ciclosN) {
      for (final p in c.participantes) {
        if (p.id > 0) ids.add(p.id);
      }
    }
    return ids;
  }

  static List<Match> filterOriginalMatches(
    List<Match> matches,
    Set<int> piIds,
  ) {
    return matches.where((m) => !piIds.contains(m.id)).toList();
  }

  static List<MatchTriangular> filterOriginalTriangulares(
    List<MatchTriangular> triangulares,
    Set<int> piIds,
  ) {
    return triangulares.where((t) {
      return !piIds.contains(t.policialB.id) && !piIds.contains(t.policialC.id);
    }).toList();
  }

  static String triangularKey(MatchTriangular t) =>
      '${t.policialB.id}_${t.policialC.id}';

  static List<MatchTriangular> piTriangularesExatas(SmartMatchResults pi) {
    return pi.triangulares.where((t) => !t.porAproximacao).toList();
  }

  static List<MatchTriangular> filterDuplicateTriangulares(
    List<MatchTriangular> classic,
    Iterable<MatchTriangular> piTriangulares,
  ) {
    final keys = piTriangulares.map(triangularKey).toSet();
    return classic.where((t) => !keys.contains(triangularKey(t))).toList();
  }

  static int countImediatosMatches(
    FullMatchResults? original,
    SmartMatchResults? pi,
    Set<int> piIds,
  ) {
    var count = 0;
    if (pi != null) {
      count += pi.diretas.length;
      count += piTriangularesExatas(pi).length;
    }
    if (original != null) {
      count += filterOriginalMatches(original.diretas, piIds).length;
      final piExactTri = pi != null ? piTriangularesExatas(pi) : const <MatchTriangular>[];
      count += filterDuplicateTriangulares(original.triangulares, piExactTri).length;
    }
    return count;
  }

  static int countProximidadeMatches(
    FullMatchResults? original,
    SmartMatchResults? pi,
    Set<int> piIds,
  ) {
    var count = 0;
    if (original != null) {
      count += filterOriginalMatches(original.proximas, piIds).length;
      count += original.triangularesProximas.length;
    }
    if (pi != null) {
      count += pi.proximas.length;
      count += pi.triangulares.where((t) => t.porAproximacao).length;
    }
    return count;
  }

  /// Métricas unificadas (cliente) — espelha `mergeUnifiedMetrics` da API quando o endpoint agregado não existir.
  static PermutasCanonicalMetrics buildUnifiedMetrics(
    FullMatchResults? original,
    SmartMatchResults? pi,
  ) {
    final piIds = pi != null ? piPolicialIds(pi) : <int>{};
    return PermutasCanonicalMetrics(
      directMatches: (pi?.diretas.length ?? 0) +
          filterOriginalMatches(original?.diretas ?? const [], piIds).length,
      proximityMatches: countProximidadeMatches(original, pi, piIds),
      interestedCandidates: countInteressadosMatches(original, pi, piIds),
      cycles: pi?.ciclosN.length ?? 0,
      totalUniqueCandidates: _countUnifiedUniquePersons(original, pi, piIds),
      meta: PermutasMetricsMeta(
        cacheHit: pi?.cache.hit ?? false,
        computedAt: pi?.cache.computedAt ?? pi?.metricas?.meta.computedAt,
        algorithmVersion: 'unificado_v1',
        truncated: pi?.metricas?.meta.truncated ?? false,
        returnedCount: (original != null ? _legacyReturnedCount(original) : 0) +
            (pi?.totalMatches ?? 0),
      ),
    );
  }

  static int _legacyReturnedCount(FullMatchResults original) {
    return original.diretas.length +
        original.proximas.length +
        original.interessados.length +
        original.triangulares.length +
        original.triangularesProximas.length;
  }

  static int _countUnifiedUniquePersons(
    FullMatchResults? original,
    SmartMatchResults? pi,
    Set<int> piIds,
  ) {
    final ids = <int>{};
    void addId(int id) {
      if (id > 0) ids.add(id);
    }

    for (final m in pi?.interessados ?? const <SmartMatch>[]) {
      addId(m.id);
    }
    for (final m in filterOriginalMatches(original?.interessados ?? const [], piIds)) {
      addId(m.id);
    }
    for (final m in pi?.diretas ?? const <SmartMatch>[]) {
      addId(m.id);
    }
    for (final m in filterOriginalMatches(original?.diretas ?? const [], piIds)) {
      addId(m.id);
    }
    for (final m in pi?.proximas ?? const <SmartMatch>[]) {
      addId(m.id);
    }
    for (final m in filterOriginalMatches(original?.proximas ?? const [], piIds)) {
      addId(m.id);
    }
    final piExactTri = pi != null ? piTriangularesExatas(pi) : const <MatchTriangular>[];
    for (final t in piExactTri) {
      addId(t.policialB.id);
      addId(t.policialC.id);
    }
    for (final t in filterDuplicateTriangulares(
      original?.triangulares ?? const [],
      piExactTri,
    )) {
      addId(t.policialB.id);
      addId(t.policialC.id);
    }
    for (final t in pi?.triangulares.where((x) => x.porAproximacao) ?? const <MatchTriangular>[]) {
      addId(t.policialB.id);
      addId(t.policialC.id);
    }
    for (final t in original?.triangularesProximas ?? const <MatchTriangular>[]) {
      addId(t.policialB.id);
      addId(t.policialC.id);
    }
    for (final c in pi?.ciclosN ?? const <CicloNWay>[]) {
      for (final p in c.participantes) {
        addId(p.id);
      }
    }
    return ids.length;
  }

  static int countInteressadosMatches(
    FullMatchResults? original,
    SmartMatchResults? pi,
    Set<int> piIds,
  ) {
    var count = 0;
    if (original != null) {
      count += filterOriginalMatches(original.interessados, piIds).length;
    }
    if (pi != null) {
      count += pi.interessados.length;
    }
    return count;
  }

  static int countCompativelDashboard(
    FullMatchResults? original,
    SmartMatchResults? pi,
  ) {
    final piIds = pi != null ? piPolicialIds(pi) : <int>{};
    var count = pi?.diretas.length ?? 0;
    count += pi != null ? piTriangularesExatas(pi).length : 0;
    count += pi?.ciclosN.length ?? 0;
    if (original != null) {
      count += filterOriginalMatches(original.diretas, piIds).length;
      final piExactTri =
          pi != null ? piTriangularesExatas(pi) : const <MatchTriangular>[];
      count += filterDuplicateTriangulares(original.triangulares, piExactTri).length;
    }
    return count;
  }

  static int countOriginalMatches(FullMatchResults original, Set<int> piIds) {
    return filterOriginalMatches(original.diretas, piIds).length +
        filterOriginalMatches(original.proximas, piIds).length +
        filterOriginalMatches(original.interessados, piIds).length +
        filterOriginalTriangulares(original.triangulares, piIds).length +
        filterOriginalTriangulares(original.triangularesProximas, piIds).length;
  }

  static int countPiAdditionalMatches(
    SmartMatchResults pi,
    FullMatchResults? original,
  ) {
    if (original == null) return pi.totalMatches;

    final originalIds = <int>{};
    for (final m in original.diretas) {
      originalIds.add(m.id);
    }
    for (final m in original.proximas) {
      originalIds.add(m.id);
    }
    for (final m in original.interessados) {
      originalIds.add(m.id);
    }
    for (final t in original.triangulares) {
      originalIds.add(t.policialB.id);
      originalIds.add(t.policialC.id);
    }
    for (final t in original.triangularesProximas) {
      originalIds.add(t.policialB.id);
      originalIds.add(t.policialC.id);
    }

    var count = pi.ciclosN.length;
    for (final m in [...pi.diretas, ...pi.proximas, ...pi.interessados]) {
      if (!originalIds.contains(m.id)) count++;
    }
    for (final t in pi.triangulares) {
      if (!originalIds.contains(t.policialB.id) ||
          !originalIds.contains(t.policialC.id)) {
        count++;
      }
    }
    return count;
  }

  static bool temRaioConfigurado(List<Intencao> intencoes) {
    return intencoes.any((i) => i.raioKm != null && i.raioKm! > 0);
  }

  static String emptyStateMessage({
    required List<Intencao> intencoes,
    int? graphNodes,
  }) {
    if (intencoes.isEmpty) {
      return 'Você ainda não tem intenções cadastradas. Adicione pelo menos uma para o motor começar a trabalhar.';
    }
    if (!temRaioConfigurado(intencoes)) {
      return 'Suas intenções são exatas. Adicione um raio de proximidade para encontrar mais candidatos.';
    }
    if (graphNodes != null && graphNodes < 40) {
      return 'Sua corporação ainda tem poucos usuários ativos na rede. Convide colegas para ampliar as chances.';
    }
    return 'Nenhuma combinação no momento. O motor verifica novos usuários a cada 2 horas.';
  }
}
