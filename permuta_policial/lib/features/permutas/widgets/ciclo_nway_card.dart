import 'package:flutter/material.dart';

import '../../../core/models/match_results.dart';
import '../../../core/models/smart_match_results.dart';
import '../utils/permuta_contact_actions.dart';
import 'permuta_unificada_theme.dart';

class CicloNWayCard extends StatelessWidget {
  final CicloNWay ciclo;
  final String Function(Match) displayName;
  final bool Function(Match) isAnonimo;

  const CicloNWayCard({
    super.key,
    required this.ciclo,
    required this.displayName,
    required this.isAnonimo,
  });

  List<String> get _timelineLabels {
    final participantes = ciclo.participantes.where((p) => p.id > 0).toList();
    if (participantes.isEmpty) return ['Você', 'Você'];

    final labels = <String>['Você'];
    for (final p in participantes) {
      labels.add(displayName(p));
    }
    labels.add('Você');
    return labels;
  }

  /// Converte `descricao_resumo` ou entrada do fluxo em "Sai de X, vai para Y".
  static String movimentoTexto(SmartMatch participante, int index, CicloNWay ciclo) {
    final fromResumo = _parseMovimento(participante.descricaoResumo);
    if (fromResumo != null) return fromResumo;

    if (index < ciclo.fluxo.length) {
      final fromFluxo = _parseMovimento(ciclo.fluxo[index]);
      if (fromFluxo != null) return fromFluxo;
    }

    return _fallbackMovimento(participante);
  }

  static String? _parseMovimento(String? texto) {
    if (texto == null || texto.isEmpty) return null;

    final corpo = texto.contains(': ') ? texto.split(': ').skip(1).join(': ') : texto;
    final match = RegExp(r'está em (.+) e vai para (.+)$').firstMatch(corpo.trim());
    if (match != null) {
      return 'Sai de ${match.group(1)?.trim()}, vai para ${match.group(2)?.trim()}';
    }

    final matchAlt = RegExp(r'sai de (.+) e vai para (.+)$', caseSensitive: false)
        .firstMatch(corpo.trim());
    if (matchAlt != null) {
      return 'Sai de ${matchAlt.group(1)?.trim()}, vai para ${matchAlt.group(2)?.trim()}';
    }

    return null;
  }

  static String _fallbackMovimento(SmartMatch p) {
    final origem = _localAtual(p);
    return 'Sai de $origem, vai para destino informado';
  }

  static String _localAtual(SmartMatch p) {
    final partes = <String>[];
    if (p.municipioAtual != null && p.municipioAtual!.isNotEmpty) {
      partes.add(p.estadoAtual != null ? '${p.municipioAtual}-${p.estadoAtual}' : p.municipioAtual!);
    }
    if (p.unidadeAtual != null && p.unidadeAtual!.isNotEmpty) {
      partes.add(p.unidadeAtual!);
    }
    return partes.isEmpty ? 'local não informado' : partes.join(', ');
  }

  void _showParticipanteSheet(BuildContext context, SmartMatch participante, int index) {
    final anonimo = isAnonimo(participante);
    final movimento = movimentoTexto(participante, index, ciclo);

    showModalBottomSheet(
      context: context,
      backgroundColor: PermutaUnificadaTheme.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName(participante), style: PermutaUnificadaTheme.titleStyle(16)),
            const SizedBox(height: 6),
            Text(movimento, style: PermutaUnificadaTheme.monoStyle(12, PermutaUnificadaTheme.accent)),
            if (participante.forcaSigla.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(participante.forcaSigla, style: PermutaUnificadaTheme.monoStyle(11)),
            ],
            if (anonimo) ...[
              const SizedBox(height: 12),
              Text(
                'Usuário com privacidade ativa. Envie mensagem anônima.',
                style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.textMuted),
              ),
            ],
            const SizedBox(height: 16),
            if (!anonimo)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  PermutaContactActions.solicitarContato(
                    context,
                    destinatarioId: participante.id,
                    tipoPermuta: 'ciclo',
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Solicitar Contato'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PermutaUnificadaTheme.accent,
                  side: const BorderSide(color: PermutaUnificadaTheme.border),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                PermutaContactActions.enviarMensagemParaMatch(context, participante);
              },
              icon: const Icon(Icons.message),
              label: const Text('Mensagem'),
              style: FilledButton.styleFrom(
                backgroundColor: PermutaUnificadaTheme.heroBlue,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantes = ciclo.participantes.where((p) => p.id > 0).toList();
    final timeline = _timelineLabels;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PermutaUnificadaTheme.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PermutaUnificadaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: PermutaUnificadaTheme.accentChain, size: 18),
              const SizedBox(width: 6),
              Text('Permuta em Cadeia', style: PermutaUnificadaTheme.titleStyle(13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PermutaUnificadaTheme.bgGlass,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PermutaUnificadaTheme.border),
                ),
                child: Text(
                  '${ciclo.tamanho} pessoas',
                  style: PermutaUnificadaTheme.monoStyle(10, PermutaUnificadaTheme.textSecondary),
                ),
              ),
              if (ciclo.score != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PermutaUnificadaTheme.bgGlass,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PermutaUnificadaTheme.border),
                  ),
                  child: Text(
                    '${ciclo.score!.toStringAsFixed(0)} pts',
                    style: PermutaUnificadaTheme.monoStyle(
                      10,
                      PermutaUnificadaTheme.accentMutedGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < timeline.length; i++) ...[
                  _timelineNode(timeline[i], isSelf: timeline[i] == 'Você'),
                  if (i < timeline.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: PermutaUnificadaTheme.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (participantes.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...ciclo.participantes.asMap().entries.where((e) => e.value.id > 0).map((entry) {
              final index = entry.key;
              final p = entry.value;
              final anonimo = isAnonimo(p);
              final movimento = movimentoTexto(p, index, ciclo);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: PermutaUnificadaTheme.bgGlass,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _showParticipanteSheet(context, p, index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PermutaUnificadaTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (anonimo)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 8),
                              child: Icon(Icons.visibility_off,
                                  size: 14, color: PermutaUnificadaTheme.textSecondary),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName(p),
                                  style: PermutaUnificadaTheme.titleStyle(12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movimento,
                                  style: PermutaUnificadaTheme.monoStyle(
                                    11,
                                    PermutaUnificadaTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18, color: PermutaUnificadaTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _timelineNode(String label, {required bool isSelf}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelf ? PermutaUnificadaTheme.heroBlue.withValues(alpha: 0.15) : PermutaUnificadaTheme.bgGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelf ? PermutaUnificadaTheme.heroBlue.withValues(alpha: 0.4) : PermutaUnificadaTheme.border,
        ),
      ),
      child: Text(
        label,
        style: PermutaUnificadaTheme.monoStyle(
          9,
          isSelf ? PermutaUnificadaTheme.accent : PermutaUnificadaTheme.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
