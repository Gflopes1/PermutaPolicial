// Contrato canônico — docs/metricas-canonicas.md

class PermutasBucketMeta {
  final int returnedCount;
  final int availableCount;
  final bool truncated;

  const PermutasBucketMeta({
    this.returnedCount = 0,
    this.availableCount = 0,
    this.truncated = false,
  });

  factory PermutasBucketMeta.fromJson(Map<String, dynamic> json) {
    return PermutasBucketMeta(
      returnedCount: (json['returned_count'] as num?)?.toInt() ?? 0,
      availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
      truncated: json['truncated'] == true,
    );
  }
}

class PermutasMetricsMeta {
  final DateTime? computedAt;
  final bool cacheHit;
  final String algorithmVersion;
  final bool truncated;
  final int returnedCount;
  final int? availableCount;
  final Map<String, PermutasBucketMeta> buckets;

  const PermutasMetricsMeta({
    this.computedAt,
    this.cacheHit = false,
    this.algorithmVersion = 'unknown',
    this.truncated = false,
    this.returnedCount = 0,
    this.availableCount,
    this.buckets = const {},
  });

  factory PermutasMetricsMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PermutasMetricsMeta();
    final rawBuckets = json['buckets'];
    final buckets = <String, PermutasBucketMeta>{};
    if (rawBuckets is Map) {
      rawBuckets.forEach((key, value) {
        if (value is Map) {
          buckets[key.toString()] =
              PermutasBucketMeta.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return PermutasMetricsMeta(
      computedAt: DateTime.tryParse(json['computed_at']?.toString() ?? ''),
      cacheHit: json['cache_hit'] == true,
      algorithmVersion: json['algorithm_version']?.toString() ?? 'unknown',
      truncated: json['truncated'] == true,
      returnedCount: (json['returned_count'] as num?)?.toInt() ?? 0,
      availableCount: (json['available_count'] as num?)?.toInt(),
      buckets: buckets,
    );
  }
}

class PermutasCanonicalMetrics {
  final int directMatches;
  final int proximityMatches;
  final int interestedCandidates;
  final int cycles;
  final int totalUniqueCandidates;
  final PermutasMetricsMeta meta;

  const PermutasCanonicalMetrics({
    required this.directMatches,
    required this.proximityMatches,
    required this.interestedCandidates,
    required this.cycles,
    required this.totalUniqueCandidates,
    required this.meta,
  });

  factory PermutasCanonicalMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PermutasCanonicalMetrics(
        directMatches: 0,
        proximityMatches: 0,
        interestedCandidates: 0,
        cycles: 0,
        totalUniqueCandidates: 0,
        meta: PermutasMetricsMeta(),
      );
    }
    return PermutasCanonicalMetrics(
      directMatches: (json['direct_matches'] as num?)?.toInt() ?? 0,
      proximityMatches: (json['proximity_matches'] as num?)?.toInt() ?? 0,
      interestedCandidates: (json['interested_candidates'] as num?)?.toInt() ?? 0,
      cycles: (json['cycles'] as num?)?.toInt() ?? 0,
      totalUniqueCandidates: (json['total_unique_candidates'] as num?)?.toInt() ?? 0,
      meta: PermutasMetricsMeta.fromJson(
        json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : null,
      ),
    );
  }
}

class PermutasUnifiedMetricsResponse {
  final PermutasCanonicalMetrics metricasUnificadas;
  final int? dashboardInteressados;
  final int? dashboardMatchesCompativeis;
  final bool cacheHitInteligente;

  const PermutasUnifiedMetricsResponse({
    required this.metricasUnificadas,
    this.dashboardInteressados,
    this.dashboardMatchesCompativeis,
    this.cacheHitInteligente = false,
  });

  factory PermutasUnifiedMetricsResponse.fromJson(Map<String, dynamic> json) {
    final dashboard = json['dashboard'] is Map
        ? Map<String, dynamic>.from(json['dashboard'] as Map)
        : null;
    final cacheHit = json['cache_hit'] is Map
        ? Map<String, dynamic>.from(json['cache_hit'] as Map)
        : null;
    return PermutasUnifiedMetricsResponse(
      metricasUnificadas: PermutasCanonicalMetrics.fromJson(
        json['metricas_unificadas'] != null
            ? Map<String, dynamic>.from(json['metricas_unificadas'])
            : null,
      ),
      dashboardInteressados: (dashboard?['interessados'] as num?)?.toInt(),
      dashboardMatchesCompativeis:
          (dashboard?['matches_compativeis'] as num?)?.toInt(),
      cacheHitInteligente: cacheHit?['inteligente'] == true,
    );
  }
}
