// /lib/features/dashboard/widgets/minhas_intencoes_card.dart

import 'package:flutter/material.dart';
import '../../../core/models/intencao.dart';

class MinhasIntencoesCard extends StatelessWidget {
  final List<Intencao> intencoes;
  final VoidCallback onEdit;
  final Future<bool> Function()? onRenew;
  final Future<bool> Function()? onPermutaConcluida;

  const MinhasIntencoesCard({
    super.key,
    required this.intencoes,
    required this.onEdit,
    this.onRenew,
    this.onPermutaConcluida,
  });

  String _buildSubtitle(Intencao intencao) {
    String base;
    switch (intencao.tipoIntencao) {
      case 'ESTADO':
        base = 'Estado: ${intencao.estadoSigla ?? "N/A"}';
        break;
      case 'MUNICIPIO':
        base = 'Municipio: ${intencao.municipioNome ?? "N/A"} - ${intencao.estadoSigla ?? ""}';
        break;
      case 'UNIDADE':
        base = intencao.unidadeNome ?? 'Unidade nao especificada';
        break;
      default:
        base = 'Tipo: ${intencao.tipoIntencao}';
    }
    if (intencao.raioKm != null) {
      base += ' (raio ${intencao.raioKm} km)';
    }
    return base;
  }

  DateTime? _referenceDate(Intencao intencao) {
    return intencao.renovadoEm ?? intencao.criadoEm;
  }

  DateTime? _oldestReferenceDate(List<Intencao> items) {
    final dates = items.map(_referenceDate).whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  int? _daysToExpire(List<Intencao> items) {
    final oldest = _oldestReferenceDate(items);
    if (oldest == null) return null;
    final expiresAt = oldest.add(const Duration(days: 180));
    return expiresAt.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedIntencoes = List<Intencao>.from(intencoes)
      ..sort((a, b) => a.prioridade.compareTo(b.prioridade));
    final daysToExpire = _daysToExpire(sortedIntencoes);
    final isExpiringSoon = daysToExpire != null && daysToExpire <= 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Minhas Intenções de Destino', style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
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
                          ? 'Suas intenções serão excluídas em ${daysToExpire < 0 ? 0 : daysToExpire} dia(s). Renove para mantê-las no mapa. Se não renovar, contaremos como permuta concluída por inatividade.'
                          : 'As intenções expiram após 6 meses. Você receberá um email quando faltar 1 semana para renovar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.red.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (sortedIntencoes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Você ainda não registrou nenhuma intenção.')),
                  ],
                ),
              )
            else
              ...sortedIntencoes.map(
                (intencao) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      '${intencao.prioridade}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    'Prioridade ${intencao.prioridade}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_buildSubtitle(intencao)),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sortedIntencoes.isNotEmpty && onPermutaConcluida != null)
                  OutlinedButton.icon(
                    onPressed: () => _confirmPermutaConcluida(context),
                    icon: const Icon(Icons.verified_outlined, size: 16),
                    label: const Text('Consegui Permutar'),
                  ),
                if (sortedIntencoes.isNotEmpty && onRenew != null)
                  OutlinedButton.icon(
                    onPressed: () => _runAction(
                      context,
                      onRenew!,
                      successMessage: 'Intenções renovadas com sucesso.',
                      errorMessage: 'Erro ao renovar intenções.',
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Renovar Intenções'),
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Gerir Intencoes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<bool> Function() action, {
    required String successMessage,
    required String errorMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await action();
    messenger.showSnackBar(
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
    if (confirmed != true || onPermutaConcluida == null) return;

    await _runAction(
      context,
      onPermutaConcluida!,
      successMessage: 'Obrigado! Registramos que você conseguiu permutar.',
      errorMessage: 'Erro ao registrar a permuta.',
    );
  }
}
