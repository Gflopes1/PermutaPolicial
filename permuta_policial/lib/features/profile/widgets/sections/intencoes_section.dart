import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../core/models/intencao.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/utils/app_share.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../referral/providers/referral_provider.dart';
import '../gerir_intencoes_modal.dart';
import '../section_card.dart';

class IntencoesSection extends StatelessWidget {
  final List<Intencao> intencoes;
  final UserProfile userProfile;

  const IntencoesSection({
    super.key,
    required this.intencoes,
    required this.userProfile,
  });

  Intencao? _findIntencao(int prioridade) {
    for (final i in intencoes) {
      if (i.prioridade == prioridade) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      label: 'Intenções de permuta',
      action: TextButton.icon(
        onPressed: () {
          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
          showDialog(
            context: context,
            builder: (ctx) => ChangeNotifierProvider.value(
              value: dashboardProvider,
              child: const GerirIntencoesModal(),
            ),
          );
        },
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Gerenciar'),
      ),
      children: [
        if (intencoes.isNotEmpty) ...[
          _IntencoesExpiryBanner(intencoes: intencoes),
          const SizedBox(height: 8),
        ],
        ...List.generate(3, (i) {
          final prioridade = i + 1;
          return _IntencaoTile(prioridade: prioridade, intencao: _findIntencao(prioridade));
        }),
        if (intencoes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IntencoesActions(intencoes: intencoes, userProfile: userProfile),
        ],
      ],
    );
  }
}

class _IntencoesExpiryBanner extends StatelessWidget {
  final List<Intencao> intencoes;

  const _IntencoesExpiryBanner({required this.intencoes});

  DateTime? _referenceDate(Intencao intencao) => intencao.renovadoEm ?? intencao.criadoEm;

  int? _daysToExpire() {
    final dates = intencoes.map(_referenceDate).whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort();
    final expiresAt = dates.first.add(const Duration(days: 180));
    return expiresAt.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final daysToExpire = _daysToExpire();
    final isExpiringSoon = daysToExpire != null && daysToExpire <= 7;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpiringSoon ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpiringSoon ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpiringSoon ? Icons.warning_amber_outlined : Icons.info_outline,
            size: 20,
            color: isExpiringSoon ? Colors.red.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExpiringSoon
                  ? 'Suas intenções serão excluídas em ${daysToExpire < 0 ? 0 : daysToExpire} dia(s). Renove para mantê-las no mapa.'
                  : 'As intenções expiram após 6 meses. Você receberá um email quando faltar 1 semana para renovar.',
              style: TextStyle(
                fontSize: 12,
                color: isExpiringSoon ? Colors.red.shade900 : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntencoesActions extends StatelessWidget {
  final List<Intencao> intencoes;
  final UserProfile userProfile;

  const _IntencoesActions({required this.intencoes, required this.userProfile});

  Future<void> _runAction(
    BuildContext context,
    Future<bool> Function() action, {
    required String successMessage,
    required String errorMessage,
  }) async {
    final success = await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? successMessage : errorMessage)),
    );
  }

  Future<void> _confirmPermutaConcluida(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar permuta concluída?'),
        content: const Text(
          'Vamos registrar seu retorno e remover suas intenções ativas para que elas não apareçam mais no mapa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await _runAction(
      context,
      () => provider.markPermutaConcluida(),
      successMessage: 'Permuta concluída registrada com sucesso.',
      errorMessage: 'Erro ao registrar permuta concluída.',
    );
  }

  static String? _destinoIntencao(Intencao i) {
    switch (i.tipoIntencao) {
      case 'UNIDADE':
        return i.unidadeNome ?? i.municipioNome;
      case 'MUNICIPIO':
        return i.municipioNome;
      case 'ESTADO':
        return i.estadoSigla;
      default:
        return i.municipioNome ?? i.unidadeNome ?? i.estadoSigla;
    }
  }

  /// Ex.: "Sou PMRS (Soldado) em Pelotas e procuro permuta para Porto Alegre."
  /// Sem nome, telefone ou e-mail.
  String _fraseIntencao(Intencao? intencao) {
    final forca = userProfile.forcaSigla;
    final posto = userProfile.postoGraduacaoNome;
    String? quem;
    if (forca != null && forca.isNotEmpty) {
      quem = (posto != null && posto.isNotEmpty) ? '$forca ($posto)' : forca;
    } else if (posto != null && posto.isNotEmpty) {
      quem = posto;
    }
    final origem = userProfile.municipioAtualNome ?? userProfile.unidadeAtualNome;
    final destino = intencao != null ? _destinoIntencao(intencao) : null;

    var frase = 'Procuro permuta';
    if (quem != null && origem != null) {
      frase = 'Sou $quem em $origem e procuro permuta';
    } else if (quem != null) {
      frase = 'Sou $quem e procuro permuta';
    } else if (origem != null) {
      frase = 'Estou em $origem e procuro permuta';
    }
    if (destino != null && destino.isNotEmpty) frase += ' para $destino';
    return '$frase.';
  }

  Future<void> _shareIntencao(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
      if (referralProvider.data == null || referralProvider.data!.code.isEmpty) {
        await referralProvider.loadMyReferral();
      }
      final referralCode = referralProvider.data?.code;
      if (referralCode == null || referralCode.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível obter seu link de indicação. Tente novamente.')),
        );
        return;
      }

      // Intenção de maior prioridade (1 = principal)
      final ordenadas = [...intencoes]..sort((a, b) => a.prioridade.compareTo(b.prioridade));
      final intencao = ordenadas.isNotEmpty ? ordenadas.first : null;
      final query = intencao != null ? '?i=${intencao.id}' : '';
      final link = '${AppConfig.apiBaseUrl}/r/${Uri.encodeComponent(referralCode)}$query';

      final text = '${_fraseIntencao(intencao)} '
          'Se você quer vir para cá, cadastre-se no Permuta Policial: $link';

      final shared = await shareText(text, subject: 'Permuta Policial');
      await referralProvider.trackShare();
      if (!shared) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Texto copiado! Cole no WhatsApp ou onde quiser.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Erro ao compartilhar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _shareIntencao(context),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Compartilhar minha intenção'),
        ),
        OutlinedButton.icon(
          onPressed: () => _confirmPermutaConcluida(context),
          icon: const Icon(Icons.verified_outlined, size: 16),
          label: const Text('Consegui Permutar'),
        ),
        OutlinedButton.icon(
          onPressed: () => _runAction(
            context,
            () => provider.renewIntencoes(),
            successMessage: 'Intenções renovadas com sucesso.',
            errorMessage: 'Erro ao renovar intenções.',
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Renovar Intenções'),
        ),
      ],
    );
  }
}

class _IntencaoTile extends StatelessWidget {
  final int prioridade;
  final Intencao? intencao;

  const _IntencaoTile({required this.prioridade, this.intencao});

  String _descricao() {
    if (intencao == null) return 'Vazia — toque em Gerenciar para adicionar';
    return switch (intencao!.tipoIntencao) {
      'ESTADO' => intencao!.estadoSigla ?? 'Estado',
      'MUNICIPIO' => _formatMunicipio(intencao!),
      'UNIDADE' => intencao!.unidadeNome ?? 'Unidade',
      _ => 'Intenção',
    };
  }

  String _formatMunicipio(Intencao intencao) {
    final nome = intencao.municipioNome?.trim();
    final sigla = intencao.estadoSigla?.trim();
    if (nome != null && nome.isNotEmpty && sigla != null && sigla.isNotEmpty) {
      return '$nome · $sigla';
    }
    if (nome != null && nome.isNotEmpty) return nome;
    if (sigla != null && sigla.isNotEmpty) return sigla;
    return 'Município';
  }

  String? _subtitulo() {
    if (intencao == null || intencao!.raioKm == null) return null;
    return 'Até ${intencao!.raioKm} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vazia = intencao == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: vazia
                ? theme.colorScheme.surface
                : AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$prioridade',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vazia ? theme.textTheme.bodySmall?.color : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _descricao(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: vazia ? theme.textTheme.bodySmall?.color : null,
                    fontStyle: vazia ? FontStyle.italic : null,
                  ),
                ),
                if (_subtitulo() != null)
                  Text(_subtitulo()!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
