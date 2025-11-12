// /lib/features/admin/widgets/sugestoes_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_display_widget.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/api/api_exception.dart';

class SugestoesTab extends StatelessWidget {
  final AdminProvider provider;

  const SugestoesTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.sugestoes.isEmpty) {
          return const LoadingWidget();
        }

        if (provider.errorMessage != null && provider.sugestoes.isEmpty) {
          return ErrorDisplayWidget(
            customMessage: provider.errorMessage!,
            customTitle: 'Erro ao carregar sugestões',
            onRetry: () => provider.loadSugestoes(),
          );
        }

        if (provider.sugestoes.isEmpty) {
          return const Center(
            child: Text('Nenhuma sugestão pendente'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadSugestoes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            itemCount: provider.sugestoes.length,
            itemBuilder: (context, index) {
              final sugestao = provider.sugestoes[index];
              return _buildSugestaoCard(context, sugestao);
            },
          ),
        );
      },
    );
  }

  Widget _buildSugestaoCard(BuildContext context, dynamic sugestao) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unidade: ${sugestao['nome_sugerido'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sugestao['municipio_nome'] != null)
                        Text('Município: ${sugestao['municipio_nome']}'),
                      if (sugestao['forca_sigla'] != null)
                        Text('Força: ${sugestao['forca_sigla']}'),
                      Text(
                        'Sugerido em: ${_formatDate(sugestao['criado_em'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejeitarSugestao(context, sugestao['id']),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSM),
                ElevatedButton.icon(
                  onPressed: () => _aprovarSugestao(context, sugestao['id']),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aprovarSugestao(BuildContext context, int sugestaoId) async {
    try {
      await provider.aprovarSugestao(sugestaoId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sugestão aprovada e unidade criada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejeitarSugestao(BuildContext context, int sugestaoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Rejeição'),
        content: const Text(
          'Tem certeza que deseja rejeitar esta sugestão?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.rejeitarSugestao(sugestaoId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sugestão rejeitada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorMessageHelper.getFriendlyMessage(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}

