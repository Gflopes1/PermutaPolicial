// /lib/features/notificacoes/screens/notificacoes_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificacoes_provider.dart';
import '../../../core/models/notificacao.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificacoesProvider>(context, listen: false).loadNotificacoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Volta para a tela anterior
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificações'),
        actions: [
          Consumer<NotificacoesProvider>(
            builder: (context, provider, child) {
              if (provider.notificacoes.where((n) => !n.lida).isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => provider.marcarTodasComoLidas(),
                child: const Text('Marcar todas como lidas'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificacoesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar notificações'),
                  const SizedBox(height: 8),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadNotificacoes(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (provider.notificacoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você não tem notificações no momento',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotificacoes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notificacoes.length,
              itemBuilder: (context, index) {
                final notificacao = provider.notificacoes[index];
                return _buildNotificacaoCard(context, notificacao, provider);
              },
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildNotificacaoCard(
    BuildContext context,
    Notificacao notificacao,
    NotificacoesProvider provider,
  ) {
    final theme = Theme.of(context);
    final isNaoLida = !notificacao.lida;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isNaoLida ? theme.colorScheme.primaryContainer.withAlpha(51) : null,
      child: InkWell(
        onTap: () => _handleNotificacaoTap(context, notificacao, provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notificacao.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isNaoLida ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isNaoLida)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (notificacao.mensagem != null) ...[
                const SizedBox(height: 8),
                Text(
                  notificacao.mensagem!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (notificacao.tipo == 'SOLICITACAO_CONTATO' && !notificacao.lida) ...[
                const SizedBox(height: 16),
                _buildSolicitacaoContatoInfo(notificacao),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _responderSolicitacao(context, notificacao, provider, false),
                      child: const Text('Negar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _responderSolicitacao(context, notificacao, provider, true),
                      child: const Text('Aceitar'),
                    ),
                  ],
                ),
              ],
              if (notificacao.tipo == 'SOLICITACAO_CONTATO_ACEITA') ...[
                const SizedBox(height: 16),
                _buildAceitadorInfo(notificacao),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(notificacao.criadoEm),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitacaoContatoInfo(Notificacao notificacao) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 96, 146),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O usuário:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade200),
          ),
          if (notificacao.solicitanteNome != null)
            Text('Nome: ${notificacao.solicitanteNome}'),
          if (notificacao.solicitanteForcaNome != null)
            Text('Força: ${notificacao.solicitanteForcaNome}'),
          if (notificacao.solicitanteEstadoSigla != null)
            Text('Estado: ${notificacao.solicitanteEstadoSigla}'),
          if (notificacao.solicitanteCidadeNome != null)
            Text('Cidade: ${notificacao.solicitanteCidadeNome}'),
          if (notificacao.solicitantePostoNome != null)
            Text('Cargo/Posto: ${notificacao.solicitantePostoNome}'),
          if (notificacao.solicitanteContato != null)
            Text('Contato: ${notificacao.solicitanteContato}'),
          const SizedBox(height: 8),
          Text(
            'Solicitou seu contato, deseja aceitar?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade200),
          ),
        ],
      ),
    );
  }

  Widget _buildAceitadorInfo(Notificacao notificacao) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de quem aceitou:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade200),
          ),
          const SizedBox(height: 8),
          if (notificacao.aceitadorNome != null)
            Text('Nome: ${notificacao.aceitadorNome}'),
          if (notificacao.aceitadorForcaSigla != null)
            Text('Força: ${notificacao.aceitadorForcaSigla}'),
          if (notificacao.aceitadorEstadoSigla != null)
            Text('Estado: ${notificacao.aceitadorEstadoSigla}'),
          if (notificacao.aceitadorCidadeNome != null)
            Text('Cidade: ${notificacao.aceitadorCidadeNome}'),
          if (notificacao.aceitadorUnidadeNome != null)
            Text('Unidade: ${notificacao.aceitadorUnidadeNome}'),
          if (notificacao.aceitadorPostoNome != null)
            Text('Posto/Graduação: ${notificacao.aceitadorPostoNome}'),
          if (notificacao.aceitadorContato != null)
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.green.shade200),
                const SizedBox(width: 4),
                Text('Telefone: ${notificacao.aceitadorContato}'),
              ],
            ),
        ],
      ),
    );
  }

  void _handleNotificacaoTap(
    BuildContext context,
    Notificacao notificacao,
    NotificacoesProvider provider,
  ) {
    if (!notificacao.lida) {
      provider.marcarComoLida(notificacao.id);
    }
  }

  Future<void> _responderSolicitacao(
    BuildContext context,
    Notificacao notificacao,
    NotificacoesProvider provider,
    bool aceitar,
  ) async {
    final success = await provider.responderSolicitacaoContato(notificacao.id, aceitar);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceitar ? 'Solicitação aceita!' : 'Solicitação negada.'),
          backgroundColor: aceitar ? Colors.green : Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao processar solicitação.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Agora';
        }
        return '${difference.inMinutes} min atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

