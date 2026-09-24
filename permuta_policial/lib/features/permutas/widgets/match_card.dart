import 'package:flutter/material.dart';

import '../../../core/models/match_results.dart';
import '../../../core/models/smart_match_results.dart';
import '../models/match_tipo.dart';
import '../utils/permuta_contact_actions.dart';
import 'permuta_unificada_theme.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final MatchTipo tipo;
  final double? score;
  final bool jaSolicitado;
  final VoidCallback? onContatoSolicitado;

  const MatchCard({
    super.key,
    required this.match,
    required this.tipo,
    this.score,
    this.jaSolicitado = false,
    this.onContatoSolicitado,
  });

  factory MatchCard.fromSmart(
    SmartMatch smart, {
    required MatchTipo tipo,
    required bool jaSolicitado,
    VoidCallback? onContatoSolicitado,
  }) {
    return MatchCard(
      match: smart,
      tipo: tipo,
      score: smart.score,
      jaSolicitado: jaSolicitado,
      onContatoSolicitado: onContatoSolicitado,
    );
  }

  bool get _isAnonimo => match.ocultarNoMapa && !match.aceitouCompartilhar;

  String get _displayName {
    if (_isAnonimo) return 'Usuário não identificado';
    if (match.ocultarNoMapa &&
        match.aceitouCompartilhar &&
        match.dadosAceitacao != null) {
      return match.dadosAceitacao!['nome']?.toString() ??
          match.dadosAceitacao!['aceitador_nome']?.toString() ??
          match.nome;
    }
    return match.nome;
  }

  String get _localizacao {
    final partes = <String>[];
    if (match.municipioAtual != null && match.municipioAtual!.isNotEmpty) {
      partes.add(match.estadoAtual != null
          ? '${match.municipioAtual}-${match.estadoAtual}'
          : match.municipioAtual!);
    }
    if (match.unidadeAtual != null && match.unidadeAtual!.isNotEmpty) {
      partes.add(match.unidadeAtual!);
    }
    return partes.isEmpty ? 'Local não informado' : partes.join(' · ');
  }

  Color get _tipoColor {
    switch (tipo) {
      case MatchTipo.direta:
        return PermutaUnificadaTheme.accentMutedGreen;
      case MatchTipo.ciclo:
        return PermutaUnificadaTheme.accentChain;
      case MatchTipo.triangular:
        return PermutaUnificadaTheme.heroBlue;
      case MatchTipo.proxima:
      case MatchTipo.interessado:
        return PermutaUnificadaTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PermutaUnificadaTheme.glassCard(accent: _tipoColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTipoBadge(),
              const Spacer(),
              if (score != null && score! >= 1000) _buildScoreBadge(),
            ],
          ),
          const SizedBox(height: 10),
          if (_isAnonimo) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.visibility_off,
                    size: 16, color: PermutaUnificadaTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este usuário optou por privacidade. A identidade permanece oculta; '
                    'você pode enviar mensagem anônima.',
                    style: PermutaUnificadaTheme.monoStyle(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(_displayName, style: PermutaUnificadaTheme.titleStyle(14)),
          const SizedBox(height: 4),
          Text(_localizacao, style: PermutaUnificadaTheme.monoStyle(11)),
          const SizedBox(height: 4),
          Text(
            '${match.forcaSigla}${match.postoGraduacaoNome != null ? ' · ${match.postoGraduacaoNome}' : ''}',
            style: PermutaUnificadaTheme.monoStyle(10, PermutaUnificadaTheme.textMuted),
          ),
          if (match.distanciaKm != null) ...[
            const SizedBox(height: 4),
            Text(
              '${match.distanciaKm!.toStringAsFixed(1)} km de distância',
              style: PermutaUnificadaTheme.monoStyle(10, PermutaUnificadaTheme.accentBlue),
            ),
          ],
          if (match.descricaoInteresse != null &&
              match.descricaoInteresse!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              match.descricaoInteresse!,
              style: PermutaUnificadaTheme.monoStyle(10, PermutaUnificadaTheme.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!_isAnonimo)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: jaSolicitado
                        ? null
                        : () => PermutaContactActions.solicitarContato(
                              context,
                              destinatarioId: match.id,
                              tipoPermuta: tipo.tipoPermutaApi,
                              onSuccess: onContatoSolicitado,
                            ),
                    icon: Icon(
                      jaSolicitado ? Icons.check_circle : Icons.person_add,
                      size: 18,
                    ),
                    label: Text(
                      jaSolicitado ? 'Contato Solicitado' : 'Solicitar Contato',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PermutaUnificadaTheme.accent,
                      side: const BorderSide(color: PermutaUnificadaTheme.border),
                    ),
                  ),
                ),
              if (!_isAnonimo) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      PermutaContactActions.enviarMensagemParaMatch(context, match),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text(
                    'Mensagem',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: PermutaUnificadaTheme.heroBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _tipoColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _tipoColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        tipo.label,
        style: PermutaUnificadaTheme.monoStyle(9, _tipoColor),
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PermutaUnificadaTheme.accentMutedGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PermutaUnificadaTheme.accentMutedGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '${score!.toStringAsFixed(0)} pts',
        style: PermutaUnificadaTheme.monoStyle(
          10,
          PermutaUnificadaTheme.accentMutedGreen,
        ),
      ),
    );
  }
}
