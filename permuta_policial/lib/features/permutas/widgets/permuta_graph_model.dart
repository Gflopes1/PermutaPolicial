import '../../../core/models/smart_match_results.dart';

enum PermutaGraphNodeKind { self, direct, proxima, triangular, ciclo, interessado, overflow }

class PermutaGraphNode {
  final String id;
  final String label;
  final String? subtitle;
  final PermutaGraphNodeKind kind;
  final double? score;
  final int? policialId;

  const PermutaGraphNode({
    required this.id,
    required this.label,
    this.subtitle,
    required this.kind,
    this.score,
    this.policialId,
  });
}

class PermutaGraphEdge {
  final String fromId;
  final String toId;
  final double weight;

  const PermutaGraphEdge({
    required this.fromId,
    required this.toId,
    required this.weight,
  });
}

class PermutaGraphData {
  final List<PermutaGraphNode> nodes;
  final List<PermutaGraphEdge> edges;
  final int totalMatches;
  final double? topScore;
  final int hiddenCount;

  const PermutaGraphData({
    required this.nodes,
    required this.edges,
    required this.totalMatches,
    this.topScore,
    this.hiddenCount = 0,
  });

  /// Grafo simplificado para visualização: hub-and-spoke, máx. 8 conexões.
  factory PermutaGraphData.fromResults(
    SmartMatchResults results, {
    String selfLabel = 'Você',
    String? selfSubtitle,
    int maxVisible = 8,
  }) {
    final candidates = <_Candidate>[];

    for (final m in results.diretas) {
      candidates.add(_Candidate(
        id: m.id,
        nome: m.nome,
        municipio: m.municipioAtual,
        kind: PermutaGraphNodeKind.direct,
        score: m.score ?? 0,
        priority: 0,
      ));
    }
    for (final m in results.proximas) {
      candidates.add(_Candidate(
        id: m.id,
        nome: m.nome,
        municipio: m.municipioAtual,
        kind: PermutaGraphNodeKind.proxima,
        score: m.score ?? 0,
        priority: 1,
      ));
    }
    for (final c in results.ciclosN) {
      for (var i = 1; i < c.participantes.length; i++) {
        final p = c.participantes[i];
        candidates.add(_Candidate(
          id: p.id,
          nome: p.nome,
          municipio: p.municipioAtual,
          kind: PermutaGraphNodeKind.ciclo,
          score: c.score ?? 0,
          priority: 2,
        ));
      }
    }
    for (final t in results.triangulares) {
      for (final p in [t.policialB, t.policialC]) {
        candidates.add(_Candidate(
          id: p.id,
          nome: p.nome,
          municipio: p.municipioAtual,
          kind: PermutaGraphNodeKind.triangular,
          score: 0,
          priority: 3,
        ));
      }
    }
    for (final m in results.interessados) {
      candidates.add(_Candidate(
        id: m.id,
        nome: m.nome,
        municipio: m.municipioAtual,
        kind: PermutaGraphNodeKind.interessado,
        score: m.score ?? 0,
        priority: 4,
      ));
    }

    final byId = <int, _Candidate>{};
    for (final c in candidates) {
      final existing = byId[c.id];
      if (existing == null || c.priority < existing.priority || c.score > existing.score) {
        byId[c.id] = c;
      }
    }

    final sorted = byId.values.toList()
      ..sort((a, b) {
        if (a.priority != b.priority) return a.priority.compareTo(b.priority);
        return b.score.compareTo(a.score);
      });

    final visible = sorted.take(maxVisible).toList();
    final hiddenCount = sorted.length - visible.length;

    final nodes = <PermutaGraphNode>[
      PermutaGraphNode(
        id: 'self',
        label: selfLabel,
        subtitle: selfSubtitle,
        kind: PermutaGraphNodeKind.self,
      ),
    ];
    final edges = <PermutaGraphEdge>[];

    for (final c in visible) {
      final nodeId = 'p_${c.id}';
      nodes.add(PermutaGraphNode(
        id: nodeId,
        label: _shortLabel(c.nome),
        subtitle: c.municipio,
        kind: c.kind,
        score: c.score > 0 ? c.score : null,
        policialId: c.id,
      ));
      edges.add(PermutaGraphEdge(
        fromId: 'self',
        toId: nodeId,
        weight: _normScore(c.score > 0 ? c.score : null),
      ));
    }

    if (hiddenCount > 0) {
      nodes.add(PermutaGraphNode(
        id: 'overflow',
        label: '+$hiddenCount',
        subtitle: 'outros matches',
        kind: PermutaGraphNodeKind.overflow,
      ));
    }

    final scores = [
      ...results.diretas.map((e) => e.score),
      ...results.proximas.map((e) => e.score),
      ...results.ciclosN.map((e) => e.score),
    ].whereType<double>();

    return PermutaGraphData(
      nodes: nodes,
      edges: edges,
      totalMatches: results.totalMatches,
      topScore: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
      hiddenCount: hiddenCount,
    );
  }
}

class _Candidate {
  final int id;
  final String nome;
  final String? municipio;
  final PermutaGraphNodeKind kind;
  final double score;
  final int priority;

  _Candidate({
    required this.id,
    required this.nome,
    this.municipio,
    required this.kind,
    required this.score,
    required this.priority,
  });
}

String _shortLabel(String nome) {
  final parts = nome.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.length > 12 ? '${parts.first.substring(0, 11)}…' : parts.first;
  }
  return '${parts.first} ${parts.last.isNotEmpty ? parts.last[0] : ''}.'.trim();
}

double _normScore(double? score) {
  if (score == null) return 0.5;
  return (score / 1200).clamp(0.2, 1.0);
}
