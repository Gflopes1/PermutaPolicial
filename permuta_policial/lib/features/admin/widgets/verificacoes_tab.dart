// /lib/features/admin/widgets/verificacoes_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_display_widget.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/api/api_exception.dart';

class VerificacoesTab extends StatelessWidget {
  final AdminProvider provider;

  const VerificacoesTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.verificacoes.isEmpty) {
          return const LoadingWidget();
        }

        if (provider.errorMessage != null &&
            provider.verificacoes.isEmpty) {
          return ErrorDisplayWidget(
            customMessage: provider.errorMessage!,
            customTitle: 'Erro ao carregar verificações',
            onRetry: () => provider.loadVerificacoes(),
          );
        }

        if (provider.verificacoes.isEmpty) {
          return const Center(
            child: Text('Nenhuma verificação pendente'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadVerificacoes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            itemCount: provider.verificacoes.length,
            itemBuilder: (context, index) {
              final verificacao = provider.verificacoes[index];
              return _buildVerificacaoCard(context, verificacao);
            },
          ),
        );
      },
    );
  }

  Widget _buildVerificacaoCard(BuildContext context, dynamic verificacao) {
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
                        verificacao['nome'] ?? 'Sem nome',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: ${verificacao['email'] ?? 'N/A'}'),
                      if (verificacao['forca_sigla'] != null)
                        Text('Força: ${verificacao['forca_sigla']}'),
                      Text(
                        'Cadastrado em: ${_formatDate(verificacao['criado_em'])}',
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
                  onPressed: () => _rejeitarPolicial(context, verificacao['id']),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSM),
                ElevatedButton.icon(
                  onPressed: () => _verificarPolicial(context, verificacao['id']),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Verificar'),
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

  Future<void> _verificarPolicial(BuildContext context, int policialId) async {
    try {
      await provider.verificarPolicial(policialId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Policial verificado com sucesso'),
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

  Future<void> _rejeitarPolicial(BuildContext context, int policialId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Rejeição'),
        content: const Text(
          'Tem certeza que deseja rejeitar este policial?',
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
        await provider.rejeitarPolicial(policialId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Policial rejeitado'),
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

