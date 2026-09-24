import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_router.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/models/edital_resumo.dart';
import '../providers/editais_hub_provider.dart';

class EditaisHubScreen extends StatefulWidget {
  const EditaisHubScreen({super.key});

  @override
  State<EditaisHubScreen> createState() => _EditaisHubScreenState();
}

class _EditaisHubScreenState extends State<EditaisHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditaisHubProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsapp(EditaisHubProvider provider) async {
    final numero = provider.whatsappNumero ?? '5551986200626';
    final mensagem = provider.whatsappMensagem ??
        'Olá, gostaria de enviar um edital de transferência ou de novos agentes para adicionar ao site';
    final uri = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub de Editais'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Abertos'),
            Tab(text: 'Encerrados'),
          ],
        ),
      ),
      floatingActionButton: Consumer<EditaisHubProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: () => _openWhatsapp(provider),
          icon: const Icon(Icons.chat),
          label: const Text('Enviar edital'),
        ),
      ),
      body: Consumer<EditaisHubProvider>(
        builder: (context, provider, _) {
          if (provider.status == EditaisHubStatus.loading &&
              provider.abertos.isEmpty &&
              provider.encerrados.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == EditaisHubStatus.error &&
              provider.abertos.isEmpty &&
              provider.encerrados.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage ?? 'Erro ao carregar editais'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.loadAll,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.abertos, vazio: 'Nenhum edital aberto no momento.'),
              _buildList(provider.encerrados, vazio: 'Nenhum edital encerrado.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<EditalResumo> editais, {required String vazio}) {
    if (editais.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(vazio, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EditaisHubProvider>().loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: editais.length,
        itemBuilder: (context, index) => _EditalCard(edital: editais[index]),
      ),
    );
  }
}

class _EditalCard extends StatelessWidget {
  final EditalResumo edital;

  const _EditalCard({required this.edital});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destacado = edital.destacarForca;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: destacado ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: destacado
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => context.push('${AppRoutes.editaisHub}/${edital.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          edital.titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusBadge(status: edital.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(edital.forcaSigla, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        label: Text(edital.tipoLabel, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (edital.totalVagas > 0)
                        Chip(
                          label: Text('${edital.totalVagas} vagas', style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(edital.prazoLabel, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.editalPublico(edital.id)),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Página pública (compartilhar)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'ABERTO':
        color = Colors.green;
        label = 'Aberto';
        break;
      case 'ENCERRADO':
        color = Colors.grey;
        label = 'Encerrado';
        break;
      default:
        color = Colors.orange;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
