import 'package:flutter/material.dart';

import 'permuta_unificada_theme.dart';

typedef PermutasItemBuilder = Widget Function();

/// Lista paginada com lazy build real — widgets só são criados ao renderizar o índice.
class PermutasLazyList extends StatefulWidget {
  final List<PermutasItemBuilder> itemBuilders;
  final int initialCount;
  final int pageSize;
  final String? groupLabel;

  const PermutasLazyList({
    super.key,
    required this.itemBuilders,
    this.initialCount = 5,
    this.pageSize = 5,
    this.groupLabel,
  });

  @override
  State<PermutasLazyList> createState() => _PermutasLazyListState();
}

class _PermutasLazyListState extends State<PermutasLazyList> {
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _visibleCount = widget.initialCount;
  }

  @override
  void didUpdateWidget(covariant PermutasLazyList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemBuilders.length != widget.itemBuilders.length) {
      _visibleCount = widget.initialCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemBuilders.isEmpty) return const SizedBox.shrink();

    final total = widget.itemBuilders.length;
    final shown = _visibleCount.clamp(0, total);
    final hasMore = shown < total;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: shown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= shown) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _visibleCount = (_visibleCount + widget.pageSize).clamp(0, total);
                }),
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  'Ver mais ${total - shown}'
                  '${widget.groupLabel != null ? ' ${widget.groupLabel}' : ''}',
                  style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.accent),
                ),
              ),
            ),
          );
        }
        return widget.itemBuilders[index]();
      },
    );
  }
}

/// Agrupa label + lista lazy.
class PermutasLazySubsection extends StatelessWidget {
  final String title;
  final bool highlight;
  final List<PermutasItemBuilder> itemBuilders;
  final int initialCount;

  const PermutasLazySubsection({
    super.key,
    required this.title,
    required this.itemBuilders,
    this.highlight = false,
    this.initialCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              if (highlight)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.link,
                      size: 14, color: PermutaUnificadaTheme.accentChain),
                ),
              Expanded(
                child: Text(
                  title,
                  style: PermutaUnificadaTheme.titleStyle(11).copyWith(
                    color: highlight
                        ? PermutaUnificadaTheme.accentChain
                        : PermutaUnificadaTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                '${itemBuilders.length}',
                style: PermutaUnificadaTheme.monoStyle(9, PermutaUnificadaTheme.textMuted),
              ),
            ],
          ),
        ),
        PermutasLazyList(
          itemBuilders: itemBuilders,
          initialCount: initialCount,
          groupLabel: title.toLowerCase(),
        ),
      ],
    );
  }
}
