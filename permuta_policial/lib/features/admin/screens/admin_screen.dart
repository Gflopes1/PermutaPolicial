// /lib/features/admin/screens/admin_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/admin_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/utils/cdn_photo_url.dart';
import '../../../core/services/analytics_service.dart';
import '../widgets/referral_admin_tab.dart';
import '../../questions/screens/questions_admin_screen.dart';
import '../widgets/editais_admin_tab.dart';
import '../widgets/mapa_tatico_admin_tab.dart';
import '../widgets/consultoria_juridica_admin_tab.dart';
import '../widgets/admin_graph_tab.dart';
import '../widgets/admin_analytics_tab.dart';
import '../widgets/activity_logs_admin_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _usuariosScrollController = ScrollController();
  Timer? _searchDebounce;
  bool _premiumTabInitialized = false;
  bool _performanceLogsTabInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 20, vsync: this);
    
    // Listener para scroll infinito na aba de usuários
    _usuariosScrollController.addListener(() {
      if (_usuariosScrollController.position.pixels >= 
          _usuariosScrollController.position.maxScrollExtent * 0.8) {
        final provider = Provider.of<AdminProvider>(context, listen: false);
        if (provider.hasMorePoliciais && !provider.isLoadingMorePoliciais) {
          provider.loadMorePoliciais();
        }
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAdminScreen();
    });
  }

  Future<void> _initializeAdminScreen() async {
    try {
      await _trackPageView();
      
      final provider = Provider.of<AdminProvider>(context, listen: false);
      
      // Carrega dados em paralelo com tratamento de erro individual
      await Future.wait([
        provider.loadEstatisticas().catchError((e) {
          debugPrint('Erro ao carregar estatísticas: $e');
        }),
        provider.loadSugestoes().catchError((e) {
          debugPrint('Erro ao carregar sugestões: $e');
        }),
        provider.loadVerificacoes().catchError((e) {
          debugPrint('Erro ao carregar verificações: $e');
        }),
        provider.loadPoliciais().catchError((e) {
          debugPrint('Erro ao carregar policiais: $e');
        }),
        provider.loadParceiros().catchError((e) {
          debugPrint('Erro ao carregar parceiros: $e');
        }),
        provider.loadAnalytics().catchError((e) {
          debugPrint('Erro ao carregar analytics: $e');
        }),
        provider.loadConfiguracoes().catchError((e) {
          debugPrint('Erro ao carregar configurações: $e');
        }),
        provider.loadProblemaRelatos().catchError((e) {
          debugPrint('Erro ao carregar relatos de problemas: $e');
        }),
        provider.loadPermutasConcluidas().catchError((e) {
          debugPrint('Erro ao carregar permutas concluídas: $e');
        }),
      ]);
      
      // Carrega dados do marketplace separadamente
      try {
        final marketplaceProvider = Provider.of<MarketplaceProvider>(context, listen: false);
        await Future.wait([
          marketplaceProvider.loadItensAdmin().catchError((e) {
            debugPrint('Erro ao carregar itens admin do marketplace: $e');
          }),
          marketplaceProvider.loadPendentesCount().catchError((e) {
            debugPrint('Erro ao carregar contagem pendente do marketplace: $e');
          }),
        ]);
      } catch (e) {
        debugPrint('Erro ao inicializar marketplace provider: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Erro ao inicializar painel de administração: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Mostra erro ao usuário se o contexto ainda estiver montado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao carregar dados do painel. Alguns dados podem não estar disponíveis.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/admin');
    } catch (e) {
      debugPrint('Erro ao rastrear page view do admin: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usuariosScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.group_add), text: 'Indicações'),
            Tab(icon: Icon(Icons.people), text: 'Usuários'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verificações'),
            Tab(icon: Icon(Icons.location_city), text: 'Sugestões'),
            Tab(icon: Icon(Icons.business), text: 'Anunciantes'),
            Tab(icon: Icon(Icons.gavel), text: 'Consultoria'),
            Tab(icon: Icon(Icons.store), text: 'Marketplace'),
            Tab(icon: Icon(Icons.quiz), text: 'Questões'),
            Tab(icon: Icon(Icons.star), text: 'Premium'),
            Tab(icon: Icon(Icons.bug_report), text: 'Relatos'),
            Tab(icon: Icon(Icons.celebration), text: 'Permutas OK'),
            Tab(icon: Icon(Icons.email), text: 'E-mail'),
            Tab(icon: Icon(Icons.description), text: 'Editais'),
            Tab(icon: Icon(Icons.map), text: 'Mapa Tático'),
            Tab(icon: Icon(Icons.hub), text: 'Grafo'),
            Tab(icon: Icon(Icons.history), text: 'Log de Ações'),
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
            Tab(icon: Icon(Icons.settings), text: 'Configurações'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              if (provider.errorMessage != null)
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  leading: const Icon(Icons.warning_amber, color: AppTheme.error),
                  actions: [
                    TextButton(
                      onPressed: () {
                        provider.loadEstatisticas();
                        provider.loadSugestoes();
                        provider.loadVerificacoes();
                        provider.loadPoliciais();
                        provider.loadParceiros();
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEstatisticasTab(provider),
                    const AdminAnalyticsTab(),
                    const ReferralAdminTab(),
                    _buildUsuariosTab(provider),
                    _buildVerificacoesTab(provider),
                    _buildSugestoesTab(provider),
                    _buildAnunciantesTab(provider),
                    const ConsultoriaJuridicaAdminTab(),
                    _buildMarketplaceTab(),
                    _buildQuestoesTab(),
                    _buildPremiumTab(provider),
                    _buildProblemaRelatosTab(provider),
                    _buildPermutasConcluidasTab(provider),
                    _buildEmailTab(provider),
                    const EditaisAdminTab(),
                    const MapaTaticoAdminTab(),
                    const AdminGraphTab(),
                    const ActivityLogsAdminTab(),
                    _buildPerformanceLogsTab(provider),
                    _buildConfiguracoesTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEstatisticasTab(AdminProvider provider) {
    if (provider.isLoading && provider.estatisticas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = provider.estatisticas ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Total de Policiais', stats['total_policiais']?.toString() ?? '0', Icons.people),
        const SizedBox(height: 16),
        _buildStatCard('Total de Unidades', stats['total_unidades']?.toString() ?? '0', Icons.location_city),
        const SizedBox(height: 16),
        _buildStatCard('Total de Intenções', stats['total_intencoes']?.toString() ?? '0', Icons.favorite),
        const SizedBox(height: 16),
        _buildStatCard('Verificações Pendentes', stats['verificacoes_pendentes']?.toString() ?? '0', Icons.pending),
        const SizedBox(height: 16),
        _buildStatCard('OCR pendentes', stats['verificacoes_ocr_pendentes']?.toString() ?? '0', Icons.document_scanner_outlined),
        const SizedBox(height: 16),
        _buildStatCard('Permutas Concluídas', stats['total_permutas_concluidas']?.toString() ?? '0', Icons.celebration),
        const SizedBox(height: 16),
        _buildStatCard('Relatos Pendentes', stats['total_relatos_pendentes']?.toString() ?? '0', Icons.bug_report),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool isMobile = false}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: isMobile ? 22 : 24),
            ),
            SizedBox(width: isMobile ? 16 : 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 13 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuariosTab(AdminProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar usuário',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Cancela a busca anterior
              _searchDebounce?.cancel();
              
              // Inicia nova busca após 500ms sem digitar
              _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  provider.loadPoliciais(search: value.isEmpty ? null : value);
                }
              });
            },
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.policiais.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.policiais.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.'))
                  : ListView.builder(
                      controller: _usuariosScrollController,
                      itemCount: provider.policiais.length + (provider.hasMorePoliciais ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Se for o último item e ainda há mais, mostra loading
                        if (index == provider.policiais.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        final policial = provider.policiais[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(policial['nome']?[0] ?? '?'),
                            ),
                            title: Text(policial['nome'] ?? 'Sem nome'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: ${policial['email'] ?? 'N/A'}'),
                                Text('Status: ${policial['status_verificacao'] ?? 'N/A'}'),
                                if (policial['unidade_atual'] != null)
                                  Text('Unidade: ${policial['unidade_atual']}'),
                                Row(
                                  children: [
                                    if ((policial['is_moderator'] ?? policial['embaixador'] ?? 0) == 1)
                                      Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Moderador/Admin', style: TextStyle(fontSize: 10)),
                                      ),
                                    if ((policial['is_premium'] ?? 0) == 1)
                                      Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Premium', style: TextStyle(fontSize: 10)),
                                      ),
                                    if ((policial['agente_verificado'] ?? 0) == 1 || policial['agente_verificado'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Verificado', style: TextStyle(fontSize: 10)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Editar',
                                  onPressed: () => _showEditPolicialDialog(context, provider, policial),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Excluir conta',
                                  onPressed: () => _confirmarExclusaoPolicial(context, provider, policial),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildVerificacoesTab(AdminProvider provider) {
    if (provider.isLoading && provider.verificacoes.isEmpty && provider.verificacoesOcr.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.verificacoes.isEmpty && provider.verificacoesOcr.isEmpty) {
      return const Center(child: Text('Nenhuma verificação pendente.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.verificacoesOcr.isNotEmpty) ...[
          Text(
            'Revisão OCR (${provider.verificacoesOcr.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...provider.verificacoesOcr.map((item) => _buildOcrVerificacaoCard(provider, item)),
          const SizedBox(height: 24),
        ],
        if (provider.verificacoes.isNotEmpty) ...[
          Text(
            'Fila manual / WhatsApp (${provider.verificacoes.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...provider.verificacoes.map((verificacao) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(verificacao['nome'] ?? 'Sem nome'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${verificacao['email'] ?? 'N/A'}'),
                      Text('Força: ${verificacao['forca_sigla'] ?? 'N/A'}'),
                      Text('Data: ${verificacao['criado_em'] ?? 'N/A'}'),
                      const Text('Origem: manual / WhatsApp'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          final success = await provider.verificarPolicial(verificacao['id']);
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Policial verificado com sucesso!')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final success = await provider.rejeitarPolicial(verificacao['id']);
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Policial rejeitado.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildOcrVerificacaoCard(AdminProvider provider, Map<String, dynamic> item) {
    final imageUrl = item['imagem_redigida_url']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.document_scanner_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['nome']?.toString() ?? 'Sem nome',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text((item['tipo_documento'] ?? 'ocr').toString()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: ${item['email'] ?? 'N/A'}'),
            Text('Força cadastrada: ${item['forca_sigla'] ?? 'N/A'}'),
            Text('ID cadastrado: ${item['id_funcional'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Nome extraído: ${item['nome_extraido'] ?? '—'}'),
            Text('Matrícula extraída: ${item['matricula_extraida'] ?? '—'}'),
            Text('Força extraída: ${item['forca_extraida'] ?? '—'}'),
            if (item['cargo_extraido'] != null) Text('Cargo extraído: ${item['cargo_extraido']}'),
            Text('Enviado em: ${item['criado_em'] ?? 'N/A'}'),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('Não foi possível carregar a imagem redigida.'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Aprovar OCR',
                  onPressed: () async {
                    final ocrId = (item['id'] as num?)?.toInt();
                    if (ocrId == null) return;
                    final success = await provider.aprovarVerificacaoOcr(ocrId);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verificação OCR aprovada!')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Rejeitar OCR',
                  onPressed: () async {
                    final ocrId = (item['id'] as num?)?.toInt();
                    if (ocrId == null) return;
                    final success = await provider.rejeitarVerificacaoOcr(ocrId);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verificação OCR rejeitada.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSugestoesTab(AdminProvider provider) {
    if (provider.isLoading && provider.sugestoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.sugestoes.isEmpty) {
      return const Center(child: Text('Nenhuma sugestão pendente.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.sugestoes.length,
      itemBuilder: (context, index) {
        final sugestao = provider.sugestoes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(sugestao['nome_sugerido'] ?? 'Sem nome'),
            subtitle: Text('Município ID: ${sugestao['municipio_id'] ?? 'N/A'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final success = await provider.aprovarSugestao(sugestao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestão aprovada!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Erro ao aprovar sugestão'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    final success = await provider.rejeitarSugestao(sugestao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestão rejeitada.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Erro ao rejeitar sugestão'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnunciantesTab(AdminProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddParceiroDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Anunciante'),
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.parceiros.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.parceiros.isEmpty
                  ? const Center(child: Text('Nenhum anunciante cadastrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.parceiros.length,
                      itemBuilder: (context, index) {
                        final parceiro = provider.parceiros[index];
                        return _buildParceiroCard(context, provider, parceiro);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildParceiroCard(BuildContext context, AdminProvider provider, dynamic parceiro) {
    // Extrai os dados com segurança
    final int id = parceiro['id'] is int ? parceiro['id'] : int.tryParse(parceiro['id']?.toString() ?? '0') ?? 0;
    final String imagemUrl = parceiro['imagem_url']?.toString() ?? '';
    final String? linkUrl = parceiro['link_url']?.toString();
    final int ordem = parceiro['ordem'] is int ? parceiro['ordem'] : int.tryParse(parceiro['ordem']?.toString() ?? '0') ?? 0;
    final bool ativo = parceiro['ativo'] == 1 || parceiro['ativo'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: imagemUrl.isNotEmpty
            ? Image.network(
                imagemUrl,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
              )
            : const Icon(Icons.image, size: 50),
        title: Text('ID: $id ${!ativo ? "(Inativo)" : ""}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link: ${linkUrl ?? 'Nenhum'}'),
            Text('Ordem: $ordem'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditParceiroDialog(
                context,
                provider,
                id,
                imagemUrl,
                linkUrl,
                ordem,
                ativo,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarExclusaoParceiro(context, provider, id),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPolicialDialog(BuildContext context, AdminProvider provider, Map<String, dynamic> policial) {
    final nomeController = TextEditingController(text: policial['nome'] ?? '');
    final emailController = TextEditingController(text: policial['email'] ?? '');
    final idFuncionalController = TextEditingController(text: policial['id_funcional']?.toString() ?? '');
    final qsoController = TextEditingController(text: policial['qso'] ?? '');
    bool isModerator = (policial['is_moderator'] ?? policial['embaixador'] ?? 0) == 1;
    bool isPremium = (policial['is_premium'] ?? 0) == 1;
    bool isAgenteVerificado = (policial['agente_verificado'] ?? 0) == 1 || policial['agente_verificado'] == true;
    int destaqueDias = 0;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: provider.loadPolicialDetalhes(policial['id']),
            builder: (context, detalhesSnap) {
              final detalhes = detalhesSnap.data;
              final lotacao = detalhes?['lotacao'] as Map<String, dynamic>?;
              final intencoes = detalhes?['intencoes'] as List<dynamic>? ?? [];
              final matches = detalhes?['matches'] as Map<String, dynamic>?;

              return AlertDialog(
                title: Text('Editar ${policial['nome'] ?? 'Policial'}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detalhesSnap.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (detalhes != null) ...[
                        const Text('Lotação', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _formatLotacaoAdmin(lotacao),
                        ),
                        const SizedBox(height: 12),
                        const Text('Intenções', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (intencoes.isEmpty)
                          const Text('Nenhuma intenção cadastrada.')
                        else
                          ...intencoes.map((i) {
                            final tipo = i['tipo_intencao'] ?? '';
                            final destino = tipo == 'UNIDADE'
                                ? i['unidade_nome']
                                : tipo == 'MUNICIPIO'
                                    ? '${i['municipio_nome']}-${i['estado_sigla'] ?? ''}'
                                    : i['estado_sigla'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('P${i['prioridade']}: $tipo → ${destino ?? '—'}'),
                            );
                          }),
                        const SizedBox(height: 12),
                        const Text('Matches encontrados', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Total: ${matches?['total'] ?? 0}'),
                        if ((matches?['diretas'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          const Text('Diretas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ...(matches!['diretas'] as List).map(
                            (m) => Text('• ${m['nome']} — ${m['descricao'] ?? ''}', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                        if (matches != null && (matches['triangulares'] as int? ?? 0) > 0)
                          Text('Triangulares: ${matches['triangulares']}', style: const TextStyle(fontSize: 12)),
                        if (matches != null && (matches['ciclos_n'] as int? ?? 0) > 0)
                          Text('Permutas 4+: ${matches['ciclos_n']}', style: const TextStyle(fontSize: 12)),
                        const Divider(height: 24),
                      ],
                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idFuncionalController,
                  decoration: const InputDecoration(labelText: 'ID Funcional'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qsoController,
                  decoration: const InputDecoration(labelText: 'QSO'),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Moderador/Admin'),
                  subtitle: const Text('Admin e moderador = embaixador'),
                  value: isModerator,
                  onChanged: (value) {
                    setState(() {
                      isModerator = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Premium'),
                  value: isPremium,
                  onChanged: (value) {
                    setState(() {
                      isPremium = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Agente verificado'),
                  subtitle: const Text('Marca agente_verificado=1 e libera acesso a editais (se estiver na lista)'),
                  value: isAgenteVerificado,
                  onChanged: (value) {
                    setState(() {
                      isAgenteVerificado = value ?? false;
                    });
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: destaqueDias,
                  decoration: const InputDecoration(
                    labelText: 'Destaque no mapa/matches',
                    helperText: '0 = remover destaque',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Sem destaque')),
                    DropdownMenuItem(value: 7, child: Text('7 dias')),
                    DropdownMenuItem(value: 15, child: Text('15 dias')),
                    DropdownMenuItem(value: 30, child: Text('30 dias')),
                    DropdownMenuItem(value: 90, child: Text('90 dias')),
                  ],
                  onChanged: (value) => setState(() => destaqueDias = value ?? 0),
                ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                            _confirmarExclusaoPolicial(context, provider, policial);
                          },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Excluir conta'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setState(() {
                        isSaving = true;
                      });
                      final success = await provider.updatePolicial(policial['id'], {
                        'nome': nomeController.text.trim(),
                        'email': emailController.text.trim(),
                        'id_funcional': idFuncionalController.text.trim(),
                        'qso': qsoController.text.trim(),
                        'is_moderator': isModerator ? 1 : 0,
                        'embaixador': isModerator ? 1 : 0,
                        'is_premium': isPremium ? 1 : 0,
                        'agente_verificado': isAgenteVerificado ? 1 : 0,
                        'destaque_dias': destaqueDias,
                      });
                      if (!context.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        provider.loadPoliciais();
                        if (isPremium) {
                          provider.loadPremiumUsers();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Policial atualizado com sucesso!')),
                        );
                      } else {
                        setState(() {
                          isSaving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Erro ao atualizar policial'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatLotacaoAdmin(Map<String, dynamic>? lotacao) {
    if (lotacao == null) return 'Não informada';
    final partes = <String>[];
    if (lotacao['municipio'] != null) {
      partes.add('${lotacao['municipio']}${lotacao['estado'] != null ? '-${lotacao['estado']}' : ''}');
    }
    if (lotacao['unidade'] != null) partes.add(lotacao['unidade'].toString());
    return partes.isEmpty ? 'Não informada' : partes.join(' · ');
  }

  void _confirmarExclusaoPolicial(
    BuildContext context,
    AdminProvider provider,
    Map<String, dynamic> policial,
  ) {
    final nome = policial['nome'] ?? 'Sem nome';
    final email = policial['email'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: Text(
          'Tem certeza que deseja excluir permanentemente a conta de "$nome" ($email)?\n\n'
          'Esta ação não pode ser desfeita. Intenções, calendário e demais dados vinculados serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await provider.deletePolicial(policial['id'] as int);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Conta excluída com sucesso.'
                        : (provider.errorMessage ?? 'Erro ao excluir conta.'),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showBulkEmailDialog(BuildContext context, AdminProvider provider) {
    const defaultSubject = 'Comunicado — Permuta Policial';
    const defaultBody = '''Olá, {{nome}}!

Informamos que [descreva aqui a novidade, aviso ou informação importante para os usuários da plataforma].

Para dúvidas, alteração de cadastro ou exclusão de conta, entre em contato pelo WhatsApp: (51) 98620-0626.

Atenciosamente,
Equipe Permuta Policial''';

    final subjectController = TextEditingController(text: defaultSubject);
    final bodyController = TextEditingController(text: defaultBody);
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('E-mail em massa'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A mensagem será enviada a todos os usuários com e-mail cadastrado (contas verificadas e ativas). Use {{nome}} para personalizar.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Assunto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Corpo da mensagem',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: isSending
                  ? null
                  : () async {
                      setState(() => isSending = true);
                      final result = await provider.sendBulkEmail(
                        subject: subjectController.text.trim(),
                        body: bodyController.text.trim(),
                      );
                      if (!mounted) return;
                      setState(() => isSending = false);
                      if (result != null) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message']?.toString() ??
                                  'Enviados: ${result['sent'] ?? 0} de ${result['total'] ?? 0}',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Erro ao enviar e-mails.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(isSending ? 'Enviando...' : 'Enviar para todos'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParceiroDialog(BuildContext context, AdminProvider provider) {
    final imagemController = TextEditingController();
    final linkController = TextEditingController();
    final ordemController = TextEditingController(text: '0');
    bool ativo = true;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Anunciante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imagemController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem *',
                    hintText: 'https://exemplo.com/imagem.png',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Link (opcional)',
                    hintText: 'https://exemplo.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ordemController,
                  decoration: const InputDecoration(
                    labelText: 'Ordem de Exibição',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Ativo'),
                  value: ativo,
                  onChanged: (value) {
                    setState(() {
                      ativo = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imagemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL da imagem é obrigatória')),
                  );
                  return;
                }
                
                final success = await provider.createParceiro({
                  'imagem_url': imagemController.text.trim(),
                  'link_url': linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                  'ordem_exibicao': int.tryParse(ordemController.text) ?? 0,
                  'ativo': ativo,
                });
                
                if (!mounted) return;
                if (success) {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anunciante adicionado!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao adicionar anunciante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParceiroDialog(
    BuildContext context,
    AdminProvider provider,
    int id,
    String imagemUrl,
    String? linkUrl,
    int ordem,
    bool ativo,
  ) {
    final imagemController = TextEditingController(text: imagemUrl);
    final linkController = TextEditingController(text: linkUrl ?? '');
    final ordemController = TextEditingController(text: ordem.toString());
    bool ativoLocal = ativo;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Anunciante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imagemController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Link (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ordemController,
                  decoration: const InputDecoration(
                    labelText: 'Ordem de Exibição',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Ativo'),
                  value: ativoLocal,
                  onChanged: (value) {
                    setState(() {
                      ativoLocal = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imagemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL da imagem é obrigatória')),
                  );
                  return;
                }
                
                final success = await provider.updateParceiro(id, {
                  'imagem_url': imagemController.text.trim(),
                  'link_url': linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                  'ordem_exibicao': int.tryParse(ordemController.text) ?? ordem,
                  'ativo': ativoLocal,
                });
                
                if (!mounted) return;
                if (success) {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anunciante atualizado!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao atualizar anunciante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusaoParceiro(BuildContext context, AdminProvider provider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este anunciante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    if (confirm == true) {
      final success = await provider.deleteParceiro(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anunciante excluído!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao excluir anunciante'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMarketplaceTab() {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.itensAdmin.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'PENDENTE', child: Text('Pendente')),
                        DropdownMenuItem(value: 'APROVADO', child: Text('Aprovado')),
                        DropdownMenuItem(value: 'REJEITADO', child: Text('Rejeitado')),
                      ],
                      onChanged: (value) {
                        provider.loadItensAdmin(status: value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadItensAdmin(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.itensAdmin.isEmpty
                  ? const Center(child: Text('Nenhum item encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.itensAdmin.length,
                      itemBuilder: (context, index) {
                        final item = provider.itensAdmin[index];
                        return _buildMarketplaceItemCard(context, item, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketplaceItemCard(BuildContext context, MarketplaceItem item, MarketplaceProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.titulo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == 'APROVADO'
                        ? Colors.green.shade100
                        : item.status == 'REJEITADO'
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      color: item.status == 'APROVADO'
                          ? Colors.green.shade700
                          : item.status == 'REJEITADO'
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.fotos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resolveCdnPhotoUrl(item.fotos[0]),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('Tipo: ${item.tipoLabel}'),
            Text('Valor: R\$ ${item.valor.toStringAsFixed(2)}'),
            if (item.policialNome != null) Text('Vendedor: ${item.policialNome}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.status == 'PENDENTE') ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final success = await provider.aprovarItem(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item aprovado!')),
                        );
                        provider.loadItensAdmin();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final success = await provider.rejeitarItem(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item rejeitado.')),
                        );
                        provider.loadItensAdmin();
                      }
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja realmente excluir este item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (!mounted) return;
                    if (confirm == true) {
                      final success = await provider.deleteItemAdmin(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item excluído!')),
                        );
                        provider.loadItensAdmin();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestoesTab() {
    return const QuestionsAdminScreen();
  }

  String _relatoUsuarioResumo(Map<String, dynamic> relato) {
    final nome = relato['usuario_nome']?.toString().trim();
    if (nome == null || nome.isEmpty) return 'Anônimo (sem login)';
    return nome;
  }

  Widget _buildRelatoIdentificacao(Map<String, dynamic> relato) {
    final usuarioId = relato['usuario_id'];
    final nome = relato['usuario_nome']?.toString().trim();
    final email = relato['usuario_email']?.toString().trim();
    final idFuncional = relato['usuario_id_funcional']?.toString().trim();
    final forca = relato['usuario_forca_sigla']?.toString().trim();
    final qso = relato['usuario_qso']?.toString().trim();

    if (usuarioId == null && (nome == null || nome.isEmpty)) {
      return const Text(
        'Solicitante: anônimo (relato antigo, sem identificação vinculada).',
        style: TextStyle(color: Colors.orange),
      );
    }

    Future<void> copyText(String label, String value) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copiado')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Solicitante', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(height: 6),
        if (usuarioId != null) Text('ID usuário: #$usuarioId'),
        if (nome != null && nome.isNotEmpty) Text('Nome: $nome'),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Email: $email'),
              TextButton.icon(
                onPressed: () => copyText('Email', email),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent('Resposta — relato Permuta Policial')}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.email_outlined, size: 16),
                label: const Text('Responder'),
              ),
            ],
          ),
        ],
        if (idFuncional != null && idFuncional.isNotEmpty) Text('ID funcional: $idFuncional'),
        if (forca != null && forca.isNotEmpty) Text('Força: $forca'),
        if (qso != null && qso.isNotEmpty) Text('QSO: $qso'),
      ],
    );
  }

  Widget _buildProblemaRelatosTab(AdminProvider provider) {
    if (provider.isLoadingProblemaRelatos && provider.problemaRelatos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.problemaRelatosError != null && provider.problemaRelatos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.problemaRelatosError!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadProblemaRelatos(status: provider.problemaRelatosStatusFilter),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    const statusOptions = ['PENDENTE', 'EM_ANALISE', 'RESOLVIDO', 'DESCARTADO'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: provider.problemaRelatosStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    DropdownMenuItem<String?>(value: 'PENDENTE', child: Text('Pendente')),
                    DropdownMenuItem<String?>(value: 'EM_ANALISE', child: Text('Em análise')),
                    DropdownMenuItem<String?>(value: 'RESOLVIDO', child: Text('Resolvido')),
                    DropdownMenuItem<String?>(value: 'DESCARTADO', child: Text('Descartado')),
                  ],
                  onChanged: (value) => provider.loadProblemaRelatos(status: value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: () => provider.loadProblemaRelatos(status: provider.problemaRelatosStatusFilter),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Total: ${provider.totalProblemaRelatos}'),
          ),
        ),
        Expanded(
          child: provider.problemaRelatos.isEmpty
              ? const Center(child: Text('Nenhum relato encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.problemaRelatos.length,
                  itemBuilder: (context, index) {
                    final relato = provider.problemaRelatos[index];
                    final status = relato['status']?.toString() ?? 'PENDENTE';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.bug_report,
                          color: status == 'PENDENTE'
                              ? Colors.orange
                              : status == 'RESOLVIDO'
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        title: Text(relato['pagina']?.toString() ?? 'Página não informada'),
                        subtitle: Text(
                          '${_relatoUsuarioResumo(relato)} • ${relato['criado_em'] ?? ''}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildRelatoIdentificacao(relato),
                                const SizedBox(height: 12),
                                Text('Detalhes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                const SizedBox(height: 4),
                                Text(relato['detalhes']?.toString() ?? ''),
                                if (relato['resolucao'] != null && relato['resolucao'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text('Resolução: ${relato['resolucao']}'),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: statusOptions.map((option) {
                                    return OutlinedButton(
                                      onPressed: status == option
                                          ? null
                                          : () async {
                                              String? resolucao;
                                              if (option == 'RESOLVIDO' || option == 'DESCARTADO') {
                                                resolucao = await _showResolucaoDialog(context);
                                                if (!mounted) return;
                                              }
                                              final relatoId = relato['id'] is int
                                                  ? relato['id'] as int
                                                  : int.parse(relato['id'].toString());
                                              final success = await provider.atualizarProblemaRelatoStatus(
                                                relatoId,
                                                status: option,
                                                resolucao: resolucao,
                                              );
                                              if (!mounted) return;
                                              if (success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Relato marcado como $option')),
                                                );
                                              }
                                            },
                                      child: Text(option.replaceAll('_', ' ')),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<String?> _showResolucaoDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolução (opcional)'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Descreva o que foi feito...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _buildPermutasConcluidasTab(AdminProvider provider) {
    if (provider.isLoadingPermutasConcluidas && provider.permutasConcluidas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.permutasConcluidasError != null && provider.permutasConcluidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.permutasConcluidasError!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.loadPermutasConcluidas,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (provider.permutasConcluidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhuma permuta concluída registrada ainda.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: provider.loadPermutasConcluidas,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Registros de permutas bem-sucedidas (manual ou por expiração sem renovação).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: provider.loadPermutasConcluidas,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.permutasConcluidas.length,
            itemBuilder: (context, index) {
              final item = provider.permutasConcluidas[index];
              final origem = item['origem']?.toString() ?? 'MANUAL';
              final isManual = origem == 'MANUAL';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isManual ? Icons.verified : Icons.timer_off,
                    color: isManual ? Colors.green : Colors.orange,
                  ),
                  title: Text(item['policial_nome']?.toString() ?? 'Usuário'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['policial_email']?.toString() ?? ''),
                      Text('Força: ${item['forca_sigla'] ?? 'N/A'}'),
                      Text('Intenções: ${item['quantidade_intencoes'] ?? 0}'),
                      Text(
                        isManual
                            ? 'Origem: botão "Consegui Permutar"'
                            : 'Origem: expirou sem renovar',
                      ),
                      Text('Data: ${item['criado_em'] ?? ''}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTab(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email, color: Theme.of(context).colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'E-mail em massa',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Envie um comunicado por e-mail para todos os usuários com e-mail cadastrado (contas verificadas e ativas).',
              ),
              const SizedBox(height: 8),
              Text(
                'Use {{nome}} no texto para personalizar com o nome de cada destinatário.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showBulkEmailDialog(context, provider),
                  icon: const Icon(Icons.send),
                  label: const Text('Compor e enviar e-mail em massa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracoesTab(AdminProvider provider) {
    final configuracoes = provider.configuracoes;
    
        return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        final notaValue = configuracoes?['nota_atualizacao'];
        final notaController = TextEditingController(
          text: notaValue != null ? notaValue.toString() : ''
        );
        final whatsappNumeroController = TextEditingController(
          text: configuracoes?['editais_whatsapp_numero']?.toString() ?? '5551986200626',
        );
        final whatsappMensagemController = TextEditingController(
          text: configuracoes?['editais_whatsapp_mensagem']?.toString() ??
              'Olá, gostaria de enviar um edital de transferência ou de novos agentes para adicionar ao site',
        );
        final questoesValue = configuracoes?['questoes_publico_geral'];
        bool questoesPublicoGeral = questoesValue == 1 || questoesValue == true || questoesValue == '1' || questoesValue == null;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurações Gerais',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Questões disponíveis para público geral'),
                          subtitle: const Text('Permite que todos os usuários acessem o sistema de questões'),
                          value: questoesPublicoGeral,
                          onChanged: (value) {
                            setState(() {
                              questoesPublicoGeral = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nota de Atualização',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notaController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Texto da nota de atualização',
                            hintText: 'Digite a nota de atualização que será exibida aos usuários',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'WhatsApp — Hub de Editais',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: whatsappNumeroController,
                          decoration: const InputDecoration(
                            labelText: 'Número WhatsApp (com DDI)',
                            hintText: '5551986200626',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: whatsappMensagemController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Mensagem padrão do FAB',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              setState(() {
                                isSaving = true;
                              });
                              final success = await provider.updateConfiguracoes({
                                'questoes_publico_geral': questoesPublicoGeral ? 1 : 0,
                                'nota_atualizacao': notaController.text.trim(),
                                'editais_whatsapp_numero': whatsappNumeroController.text.trim(),
                                'editais_whatsapp_mensagem': whatsappMensagemController.text.trim(),
                              });
                              if (!mounted) return;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Configurações salvas com sucesso!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage ?? 'Erro ao salvar configurações'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setState(() {
                                isSaving = false;
                              });
                            },
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Salvar Configurações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motor de Grafos (Permutas Inteligentes)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Recalcula o mapa de grafos e atualiza o cache de matches. '
                          'Verifique os logs do backend para erros.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        if (provider.rebuildGraphResult != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            provider.rebuildGraphResult!,
                            style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: provider.isRebuildingGraph
                                ? null
                                : () async {
                                    final ok = await provider.rebuildPermutasInteligentesGraph();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? (provider.rebuildGraphResult ??
                                                  'Cálculo do grafo concluído.')
                                              : (provider.errorMessage ??
                                                  'Erro ao recalcular grafo.'),
                                        ),
                                        backgroundColor: ok ? null : Colors.red,
                                      ),
                                    );
                                    setState(() {});
                                  },
                            icon: provider.isRebuildingGraph
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.hub_outlined),
                            label: Text(
                              provider.isRebuildingGraph
                                  ? 'Recalculando grafo...'
                                  : 'Recalcular mapa de grafos',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTab(AdminProvider provider) {
    // Carrega usuários premium na primeira vez usando um flag para evitar loop infinito
    if (!_premiumTabInitialized && provider.premiumUsers.isEmpty && !provider.isLoadingPremiumUsers) {
      _premiumTabInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.loadPremiumUsers();
        }
      });
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPremiumUsers(),
      child: provider.isLoadingPremiumUsers && provider.premiumUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.premiumUsersError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(provider.premiumUsersError!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadPremiumUsers(),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : provider.premiumUsers.isEmpty
                  ? const Center(child: Text('Nenhum usuário premium encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.premiumUsers.length,
                      itemBuilder: (context, index) {
                        final user = provider.premiumUsers[index];
                        final subscriptionStatus = user['subscription_status'] as String? ?? 'unknown';
                        final startAt = user['start_at'] != null
                            ? DateTime.tryParse(user['start_at'].toString())
                            : null;
                        final endAt = user['end_at'] != null
                            ? DateTime.tryParse(user['end_at'].toString())
                            : null;
                        final providerName = user['provider'] as String? ?? 'N/A';
                        final autoRenew = user['auto_renew'] == 1 || user['auto_renew'] == true;

                        Color statusColor;
                        IconData statusIcon;
                        switch (subscriptionStatus) {
                          case 'active':
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                            break;
                          case 'expired':
                            statusColor = Colors.orange;
                            statusIcon = Icons.warning;
                            break;
                          case 'canceled':
                            statusColor = Colors.red;
                            statusIcon = Icons.cancel;
                            break;
                          default:
                            statusColor = Colors.grey;
                            statusIcon = Icons.help_outline;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor,
                              child: Icon(statusIcon, color: Colors.white),
                            ),
                            title: Text(
                              user['nome'] as String? ?? 'Sem nome',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: ${user['email'] ?? 'N/A'}'),
                                if (user['id_funcional'] != null)
                                  Text('ID Funcional: ${user['id_funcional']}'),
                                if (user['forca_sigla'] != null)
                                  Text('Força: ${user['forca_sigla']}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        subscriptionStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (autoRenew)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'AUTO-RENOVA',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Provedor: $providerName',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (startAt != null)
                                  Text(
                                    'Início: ${DateFormat('dd/MM/yyyy').format(startAt)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (endAt != null)
                                  Text(
                                    'Fim: ${DateFormat('dd/MM/yyyy').format(endAt)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (endAt != null && endAt.isBefore(DateTime.now()) && subscriptionStatus == 'active')
                                  Text(
                                    'EXPIRADO',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildPerformanceLogsTab(AdminProvider provider) {
    if (!_performanceLogsTabInitialized &&
        provider.performanceLogs.isEmpty &&
        !provider.isLoadingPerformanceLogs) {
      _performanceLogsTabInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.loadPerformanceLogs();
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: provider.performanceLogsModuleFilter,
                  decoration: const InputDecoration(
                    labelText: 'Módulo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'PI', child: Text('Permutas Inteligentes (PI)')),
                    DropdownMenuItem(value: 'MAPA', child: Text('Mapa (MAPA)')),
                  ],
                  onChanged: (value) => provider.loadPerformanceLogs(module: value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: () => provider.loadPerformanceLogs(
                  module: provider.performanceLogsModuleFilter,
                ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadPerformanceLogs(
              module: provider.performanceLogsModuleFilter,
            ),
            child: provider.isLoadingPerformanceLogs && provider.performanceLogs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.performanceLogsError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(provider.performanceLogsError!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.loadPerformanceLogs(
                                module: provider.performanceLogsModuleFilter,
                              ),
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : provider.performanceLogs.isEmpty
                        ? const Center(child: Text('Nenhum log de performance registrado ainda.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.performanceLogs.length,
                            itemBuilder: (context, index) {
                              final log = provider.performanceLogs[index];
                              final module = log['module']?.toString() ?? '-';
                              final event = log['event']?.toString() ?? '-';
                              final at = log['at']?.toString() ?? '';
                              final data = log['data'];
                              String dataText = '';
                              if (data is Map) {
                                dataText = data.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · ');
                              }

                              DateTime? parsedAt;
                              if (at.isNotEmpty) {
                                parsedAt = DateTime.tryParse(at)?.toLocal();
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      module.length >= 2 ? module.substring(0, 2) : module,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  title: Text('$module · $event'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (parsedAt != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm:ss').format(parsedAt),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      if (dataText.isNotEmpty)
                                        Text(
                                          dataText,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}