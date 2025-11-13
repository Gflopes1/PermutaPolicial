// /lib/features/dashboard/widgets/minhas_intencoes_card.dart

import 'package:flutter/material.dart';
import '../../../core/models/intencao.dart'; // Importando o modelo do novo local

class MinhasIntencoesCard extends StatelessWidget {
  final List<Intencao> intencoes;
  final VoidCallback onEdit;

  const MinhasIntencoesCard({
    super.key,
    required this.intencoes,
    required this.onEdit,
  });

  String _buildSubtitle(Intencao intencao) {
    switch (intencao.tipoIntencao) {
      case 'ESTADO':
        return 'Estado: ${intencao.estadoSigla ?? "N/A"}';
      case 'MUNICIPIO':
        return 'Município: ${intencao.municipioNome ?? "N/A"} - ${intencao.estadoSigla ?? ""}';
      case 'UNIDADE':
        return intencao.unidadeNome ?? "Unidade não especificada";
      default:
        return 'Tipo: ${intencao.tipoIntencao}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ordena as intenções pela prioridade para garantir a exibição correta
    final sortedIntencoes = List<Intencao>.from(intencoes)..sort((a, b) => a.prioridade.compareTo(b.prioridade));

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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As intenções são excluídas automaticamente após 6 meses do registro.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
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
              ...sortedIntencoes.map((intencao) => ListTile(
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
                  )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Gerir Intenções'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}