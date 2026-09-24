import 'package:flutter/material.dart';

import '../../../core/models/match_results.dart';
import '../utils/permuta_contact_actions.dart';
import 'permuta_unificada_theme.dart';

class TriangularMatchCard extends StatelessWidget {
  final MatchTriangular match;
  final bool porProximidade;
  final bool Function(Match) jaSolicitado;
  final void Function(int) onContatoSolicitado;
  final String Function(Match) displayName;
  final bool Function(Match) isAnonimo;

  const TriangularMatchCard({
    super.key,
    required this.match,
    this.porProximidade = false,
    required this.jaSolicitado,
    required this.onContatoSolicitado,
    required this.displayName,
    required this.isAnonimo,
  });

  void _showParticipanteSheet(BuildContext context, Match participante) {
    final anonimo = isAnonimo(participante);
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
            if (participante.municipioAtual != null) ...[
              const SizedBox(height: 4),
              Text(
                '${participante.forcaSigla} · ${participante.municipioAtual}-${participante.estadoAtual ?? ''}',
                style: PermutaUnificadaTheme.monoStyle(11),
              ),
            ],
            const SizedBox(height: 16),
            if (!anonimo)
              OutlinedButton.icon(
                onPressed: jaSolicitado(participante)
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        PermutaContactActions.solicitarContato(
                          context,
                          destinatarioId: participante.id,
                          tipoPermuta: 'triangular',
                          onSuccess: () => onContatoSolicitado(participante.id),
                        );
                      },
                icon: Icon(
                  jaSolicitado(participante) ? Icons.check_circle : Icons.person_add,
                ),
                label: Text(
                  jaSolicitado(participante) ? 'Contato Solicitado' : 'Solicitar Contato',
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PermutaUnificadaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.change_history,
                  color: PermutaUnificadaTheme.heroBlue, size: 16),
              const SizedBox(width: 6),
              Text('Permuta Triangular', style: PermutaUnificadaTheme.titleStyle(12)),
              if (porProximidade) ...[
                const SizedBox(width: 8),
                Text(
                  '(por proximidade)',
                  style: PermutaUnificadaTheme.monoStyle(9, PermutaUnificadaTheme.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _flowLine(match.fluxo.aParaB),
          _flowLine(match.fluxo.bParaC),
          _flowLine(match.fluxo.cParaA),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _participantChip(context, match.policialB),
              _participantChip(context, match.policialC),
            ],
          ),
        ],
      ),
    );
  }

  Widget _participantChip(BuildContext context, Match p) {
    return ActionChip(
      label: Text(displayName(p), style: PermutaUnificadaTheme.monoStyle(10)),
      avatar: isAnonimo(p) ? const Icon(Icons.visibility_off, size: 14) : null,
      backgroundColor: PermutaUnificadaTheme.bgGlass,
      side: const BorderSide(color: PermutaUnificadaTheme.border),
      onPressed: () => _showParticipanteSheet(context, p),
    );
  }

  Widget _flowLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('→ ',
              style: PermutaUnificadaTheme.monoStyle(
                10,
                PermutaUnificadaTheme.textSecondary,
              )),
          Expanded(child: Text(text, style: PermutaUnificadaTheme.monoStyle(10))),
        ],
      ),
    );
  }
}
