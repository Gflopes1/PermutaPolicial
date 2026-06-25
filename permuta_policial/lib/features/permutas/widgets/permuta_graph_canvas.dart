import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'permuta_graph_model.dart';
import 'permuta_inteligente_theme.dart';

/// Visualização hub-and-spoke estática (sem animação).
class PermutaGraphCanvas extends StatefulWidget {
  final PermutaGraphData graph;
  final ValueChanged<PermutaGraphNode>? onNodeTap;

  const PermutaGraphCanvas({
    super.key,
    required this.graph,
    this.onNodeTap,
  });

  @override
  State<PermutaGraphCanvas> createState() => _PermutaGraphCanvasState();
}

class _PermutaGraphCanvasState extends State<PermutaGraphCanvas> {
  String? _selectedId;

  List<PermutaGraphNode> get _peripheralNodes =>
      widget.graph.nodes.where((n) => n.id != 'self').toList();

  Map<String, Offset> _layoutNodes(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final positions = <String, Offset>{'self': center};

    final peripheral = _peripheralNodes;
    if (peripheral.isEmpty) return positions;

    final minSide = math.min(size.width, size.height);
    final radius = minSide * 0.34;
    final startAngle = -math.pi / 2;

    for (var i = 0; i < peripheral.length; i++) {
      final angle = startAngle + (2 * math.pi * i / peripheral.length);
      positions[peripheral[i].id] =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    }

    return positions;
  }

  PermutaGraphNode? _nodeAt(Offset local, Map<String, Offset> positions) {
    for (final n in widget.graph.nodes) {
      final p = positions[n.id];
      if (p == null) continue;
      final hitRadius = n.kind == PermutaGraphNodeKind.self ? 28.0 : 22.0;
      if ((p - local).distance <= hitRadius) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final positions = _layoutNodes(size);

        return GestureDetector(
          onTapDown: (d) {
            final node = _nodeAt(d.localPosition, positions);
            if (node == null || node.kind == PermutaGraphNodeKind.overflow) return;
            setState(() => _selectedId = node.id);
            widget.onNodeTap?.call(node);
          },
          child: CustomPaint(
            size: size,
            painter: _GraphPainter(
              graph: widget.graph,
              positions: positions,
              selectedId: _selectedId,
            ),
          ),
        );
      },
    );
  }
}

class _GraphPainter extends CustomPainter {
  final PermutaGraphData graph;
  final Map<String, Offset> positions;
  final String? selectedId;

  _GraphPainter({
    required this.graph,
    required this.positions,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    final center = positions['self'];
    if (center == null) return;

    // Anel guia
    final guidePaint = Paint()
      ..color = PermutaInteligenteTheme.gridLine.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final peripheral = graph.nodes.where((n) => n.id != 'self').toList();
    if (peripheral.isNotEmpty) {
      final r = (positions[peripheral.first.id]! - center).distance;
      canvas.drawCircle(center, r, guidePaint);
    }

    final nodeById = {for (final n in graph.nodes) n.id: n};

    // Apenas arestas do centro → periferia
    for (final e in graph.edges) {
      if (e.fromId != 'self') continue;
      final to = positions[e.toId];
      if (to == null) continue;

      final node = nodeById[e.toId];
      final color = _colorForKind(node?.kind ?? PermutaGraphNodeKind.direct);
      final selected = e.toId == selectedId;

      final paint = Paint()
        ..color = color.withValues(alpha: selected ? 0.75 : 0.4)
        ..strokeWidth = selected ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(center, to, paint);
    }

    for (final node in graph.nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;
      _drawNode(canvas, pos, node, node.id == selectedId);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bg = Paint()..color = PermutaInteligenteTheme.bgDeep.withValues(alpha: 0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    const step = 40.0;
    final dotPaint = Paint()
      ..color = PermutaInteligenteTheme.gridLine.withValues(alpha: 0.25);
    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  void _drawNode(Canvas canvas, Offset pos, PermutaGraphNode node, bool selected) {
    final color = _colorForKind(node.kind);
    final isSelf = node.kind == PermutaGraphNodeKind.self;
    final radius = isSelf ? 24.0 : (selected ? 18.0 : 15.0);

    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = PermutaInteligenteTheme.bgPanel
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = color.withValues(alpha: selected ? 1 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1.8,
    );

    if (isSelf) {
      _drawCenteredText(canvas, pos, 'EU', 10, color, FontWeight.bold);
    } else if (node.kind == PermutaGraphNodeKind.overflow) {
      _drawCenteredText(canvas, pos, node.label, 11, PermutaInteligenteTheme.textMuted, FontWeight.w600);
    } else {
      final initial = node.label.isNotEmpty ? node.label[0].toUpperCase() : '?';
      _drawCenteredText(canvas, pos, initial, 11, color, FontWeight.w700);
    }

    if (!isSelf && node.kind != PermutaGraphNodeKind.overflow) {
      final label = node.label;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: selected ? PermutaInteligenteTheme.textPrimary : PermutaInteligenteTheme.textMuted,
            fontSize: 9,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 64);
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + radius + 6));
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    Offset pos,
    String text,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  Color _colorForKind(PermutaGraphNodeKind kind) {
    switch (kind) {
      case PermutaGraphNodeKind.self:
        return PermutaInteligenteTheme.accentCyan;
      case PermutaGraphNodeKind.direct:
        return PermutaInteligenteTheme.accentGreen;
      case PermutaGraphNodeKind.proxima:
        return PermutaInteligenteTheme.accentCyan;
      case PermutaGraphNodeKind.triangular:
        return PermutaInteligenteTheme.accentPurple;
      case PermutaGraphNodeKind.ciclo:
        return PermutaInteligenteTheme.accentAmber;
      case PermutaGraphNodeKind.interessado:
        return const Color(0xFFFF6090);
      case PermutaGraphNodeKind.overflow:
        return PermutaInteligenteTheme.textMuted;
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.selectedId != selectedId;
}
