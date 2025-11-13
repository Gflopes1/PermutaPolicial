// /lib/features/marketplace/screens/marketplace_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_client.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  final MarketplaceItem item;

  const MarketplaceDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final baseUrl = apiClient.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.fotos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '$baseUrl${item.fotos[0]}',
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 64),
                ),
              ),
            ),
          if (item.fotos.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: item.fotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '$baseUrl${item.fotos[index]}',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.tipoLabel,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${item.valor.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Descrição',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.descricao,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (item.policialNome != null) ...[
            const SizedBox(height: 16),
            Text(
              'Vendedor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.policialNome!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (item.policialEmail != null) ...[
            const SizedBox(height: 4),
            Text(
              item.policialEmail!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações do Anúncio',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Criado em: ${_formatDate(item.criadoEm)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (item.atualizadoEm != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.update, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Atualizado em: ${_formatDate(item.atualizadoEm!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      item.status == 'APROVADO'
                          ? Icons.check_circle
                          : item.status == 'REJEITADO'
                              ? Icons.cancel
                              : Icons.schedule,
                      size: 16,
                      color: item.status == 'APROVADO'
                          ? Colors.green
                          : item.status == 'REJEITADO'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${item.statusLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: item.status == 'APROVADO'
                            ? Colors.green
                            : item.status == 'REJEITADO'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

