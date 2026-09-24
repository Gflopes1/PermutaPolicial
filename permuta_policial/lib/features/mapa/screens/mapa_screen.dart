// /lib/features/mapa/screens/mapa_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/mapa_provider.dart';
import '../../../core/models/ponto_mapa.dart';
import '../../../core/models/detalhe_municipio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/utils/json_parse_utils.dart';
import '../../../core/utils/phone_copy_utils.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/visitor_prefs.dart';
import '../../../shared/widgets/app_bar_helper.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/models/notificacao.dart';

class MapaScreen extends StatefulWidget {
  final bool isVisitorMode;

  const MapaScreen({super.key, this.isVisitorMode = false});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final Set<int> _contatosSolicitados = {}; // Rastreia IDs de policiais que já tiveram contato solicitado

  @override
  void initState() {
    super.initState();
    // Pede ao provider para carregar os dados iniciais (filtros e mapa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      if (widget.isVisitorMode) {
        VisitorPrefs.setVisitorMode(true);
      }
      Provider.of<MapaProvider>(context, listen: false).fetchInitialData();
      if (!widget.isVisitorMode) {
        _carregarContatosSolicitados();
      }
    });
  }
  
  Future<void> _carregarContatosSolicitados() async {
    try {
      final notificacoesProvider = Provider.of<NotificacoesProvider>(context, listen: false);
      await notificacoesProvider.loadNotificacoes();
      
      // Busca todas as notificações de solicitação de contato (pendentes ou aceitas)
      final notificacoes = notificacoesProvider.notificacoes;
      final solicitacoes = notificacoes.where((n) => 
        n.tipo == 'SOLICITACAO_CONTATO' || n.tipo == 'SOLICITACAO_CONTATO_ACEITA'
      ).toList();
      
      if (mounted) {
        setState(() {
          for (var notif in solicitacoes) {
            if (notif.referenciaId != null) {
              _contatosSolicitados.add(notif.referenciaId!);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar contatos solicitados: $e');
    }
  }
  
  // Verifica se o usuário aceitou compartilhar seus dados com o usuário atual
  Notificacao? _verificarAceitacaoCompartilhamento(int policialId) {
    try {
      final notificacoesProvider = Provider.of<NotificacoesProvider>(context, listen: false);
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final meuId = dashboardProvider.userData?.id;
      
      if (meuId == null) return null;
      
      // Busca notificação SOLICITACAO_CONTATO_ACEITA onde:
      // - referenciaId é o policialId (o policial que aceitou)
      // - usuarioId é meuId (eu recebi a notificação)
      final notificacoes = notificacoesProvider.notificacoes;
      for (var n in notificacoes) {
        if (n.tipo == 'SOLICITACAO_CONTATO_ACEITA' && 
            n.referenciaId == policialId && 
            n.usuarioId == meuId) {
          return n;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/mapa');
    } catch (e) {
      debugPrint('Erro ao rastrear page view do mapa: $e');
    }
  }

  void _resetMapView() {
    _mapController.move(const LatLng(-14.2350, -51.9253), 4.5);
  }

  void _fitBoundsToPontos(List<PontoMapa> pontos) {
    if (pontos.isEmpty) return;
    final lats = pontos.map((p) => p.latitude);
    final lngs = pontos.map((p) => p.longitude);
    final southWest = LatLng(lats.reduce(math.min), lngs.reduce(math.min));
    final northEast = LatLng(lats.reduce(math.max), lngs.reduce(math.max));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(southWest, northEast),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _solicitarContato(
    BuildContext modalContext,
    int policialId, {
    VoidCallback? onUiUpdate,
  }) async {
    final notificacoesProvider = Provider.of<NotificacoesProvider>(modalContext, listen: false);
    final success = await notificacoesProvider.criarSolicitacaoContato(policialId, origem: 'mapa');

    if (mounted) {
      if (success || notificacoesProvider.isDuplicate) {
        setState(() {
          _contatosSolicitados.add(policialId);
        });
        onUiUpdate?.call();
      }
      
      // Usa o contexto do Scaffold principal (não do modal) para o SnackBar aparecer acima
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        success
            ? (notificacoesProvider.isDuplicate
                ? AppStyles.successSnackBar('Contato já solicitado.')
                : AppStyles.successSnackBar('Solicitação de contato enviada com sucesso!'))
            : AppStyles.errorSnackBar(notificacoesProvider.errorMessage ?? 'Erro ao enviar solicitação.'),
      );
    }
  }
  
  Future<void> _enviarMensagem(BuildContext modalContext, int destinatarioId, bool isAnonima) async {
    final chatProvider = Provider.of<ChatProvider>(modalContext, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(modalContext, listen: false);
    final meuId = dashboardProvider.userData?.id;
    
    // Validação: verifica se não está tentando enviar mensagem para si mesmo
    if (meuId != null && destinatarioId == meuId) {
      if (mounted) {
        // Usa o contexto do Scaffold principal (não do modal) para o SnackBar aparecer acima
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Você não pode enviar mensagem para si mesmo.'),
        );
      }
      return;
    }
    
    try {
      // Inicializa o socket se necessário
      await chatProvider.initializeSocket();
      
      // Inicia a conversa (anônima se especificado)
      final conversa = await chatProvider.iniciarConversa(destinatarioId, anonima: isAnonima);
      
      if (conversa != null && mounted) {
        // Navega para a tela de conversa usando o contexto do modal (pois precisa fechar o modal)
        modalContext.push('/chat/conversa/${conversa['id']}?nome=${Uri.encodeComponent(chatConversaDisplayName(Map<String, dynamic>.from(conversa), destinatarioId))}');
      } else if (mounted) {
        // Usa o contexto do Scaffold principal (não do modal) para o SnackBar aparecer acima
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Erro ao iniciar conversa.'),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao enviar mensagem.';
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('id de usuário inválido') || errorString.contains('invalid user id')) {
          errorMessage = 'Erro: não é possível iniciar conversa com este usuário.';
        }
        // Usa o contexto do Scaffold principal (não do modal) para o SnackBar aparecer acima
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(errorMessage),
        );
      }
    }
  }

  /// Paywall suave: só quando o visitante tenta ação que exige conta.
  void _showLoginPrompt({String? message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 12),
            Expanded(child: Text('Crie sua conta')),
          ],
        ),
        content: Text(
          message ??
              'Para ver contatos, solicitar permuta e participar, você precisa criar uma conta ou fazer login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuar no mapa'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.auth);
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Entrar / Criar conta'),
          ),
        ],
      ),
    );
  }

  void _requireAccount(VoidCallback action, {String? message}) {
    if (widget.isVisitorMode) {
      _showLoginPrompt(message: message);
      return;
    }
    action();
  }

  // Mostra os detalhes do município em um BottomSheet
  void _showDetalhesModal(BuildContext context, PontoMapa ponto) async {
    final provider = Provider.of<MapaProvider>(context, listen: false);
    final tipoVis = provider.tipoVisualizacao;
    final isBalanco = tipoVis == 'balanco';
    final saindoCount = ponto.saindo ?? 0;
    final vindoCount = ponto.vindo ?? 0;
    var detalheTipo = provider.resolveTipoDetalhe(ponto);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<DetalheMunicipio>>(
              key: ValueKey(detalheTipo),
              future: provider.fetchMunicipioDetails(
                ponto.municipioId,
                tipo: detalheTipo,
                ponto: ponto,
              ),
              builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erro: ${snapshot.error}'),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48),
                      SizedBox(height: 16),
                      Text('Nenhum detalhe encontrado.'),
                    ],
                  ),
                ),
              );
            }
            final detalhes = snapshot.data!;
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detalheTipo == 'saindo'
                                ? 'Policiais querendo sair de ${ponto.nome}'
                                : 'Policiais querendo vir para ${ponto.nome}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isBalanco && saindoCount > 0 && vindoCount > 0) ...[
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'saindo',
                                  label: Text('Saindo ($saindoCount)'),
                                ),
                                ButtonSegment(
                                  value: 'vindo',
                                  label: Text('Vindo ($vindoCount)'),
                                ),
                              ],
                              selected: {detalheTipo},
                              onSelectionChanged: (selection) {
                                setModalState(() {
                                  detalheTipo = selection.first;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: detalhes.length,
                        itemBuilder: (context, index) {
                          final detalhe = detalhes[index];
                          // Verifica se o usuário aceitou compartilhar seus dados
                          final notifAceitacao = _verificarAceitacaoCompartilhamento(detalhe.policialId);
                          final aceitouCompartilhar = notifAceitacao != null;
                          final mostrarDados = !detalhe.ocultarNoMapa || aceitouCompartilhar;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mostrarDados 
                                                  ? (aceitouCompartilhar 
                                                      ? (notifAceitacao.aceitadorNome ?? detalhe.policialNome)
                                                      : detalhe.policialNome)
                                                  : 'Usuário não identificado',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (aceitouCompartilhar)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.green.shade300),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Este usuário aceitou compartilhar seus dados',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.green.shade900,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!mostrarDados) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Este usuário optou por não aparecer no mapa. A mensagem será anônima até que ele responda.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _requireAccount(
                                                    () => _enviarMensagem(context, detalhe.policialId, true),
                                                    message: 'Para enviar mensagens, crie sua conta ou faça login.',
                                                  ),
                                                  icon: const Icon(Icons.message, size: 18),
                                                  label: const Text('Enviar Mensagem'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Builder(
                                                  builder: (btnContext) {
                                                    final jaSolicitado = _contatosSolicitados.contains(detalhe.policialId);
                                                    return ElevatedButton.icon(
                                                      onPressed: jaSolicitado
                                                          ? null
                                                          : () => _requireAccount(
                                                                () => _solicitarContato(
                                                                  btnContext,
                                                                  detalhe.policialId,
                                                                  onUiUpdate: () => setModalState(() {}),
                                                                ),
                                                                message: 'Para solicitar contato, crie sua conta ou faça login.',
                                                              ),
                                                      icon: Icon(jaSolicitado ? Icons.check_circle : Icons.person_add, size: 18),
                                                      label: Text(jaSolicitado ? 'Contato Solicitado' : 'Solicitar Contato'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.orange.shade700,
                                                        foregroundColor: Colors.white,
                                                        disabledBackgroundColor: const Color.fromARGB(255, 190, 190, 190),
                                                        disabledForegroundColor: const Color.fromARGB(255, 35, 35, 35),
                                                      ),
                                                    );  
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // Mostra telefone e botões se o usuário não estiver oculto OU se aceitou compartilhar
                                    const SizedBox(height: 12),
                                    // Mostra contato quando: tem qso OU aceitou compartilhar (mesmo que qso esteja vazio)
                                    if (!widget.isVisitorMode &&
                                        mostrarDados &&
                                        ((detalhe.qso != null && detalhe.qso!.isNotEmpty) ||
                                            (aceitouCompartilhar &&
                                                notifAceitacao.aceitadorContato != null &&
                                                notifAceitacao.aceitadorContato!.isNotEmpty)))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, size: 20, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SelectableText(
                                                (aceitouCompartilhar && notifAceitacao.aceitadorContato != null && notifAceitacao.aceitadorContato!.isNotEmpty)
                                                    ? notifAceitacao.aceitadorContato as String
                                                    : (detalhe.qso ?? 'Não informado'),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 20),
                                              tooltip: 'Copiar número',
                                              onPressed: () {
                                                final tel = (aceitouCompartilhar &&
                                                        notifAceitacao.aceitadorContato != null &&
                                                        notifAceitacao.aceitadorContato!.isNotEmpty)
                                                    ? notifAceitacao.aceitadorContato as String
                                                    : (detalhe.qso ?? '');
                                                copiarTelefoneComAnalytics(
                                                  context,
                                                  telefone: tel,
                                                  origem: 'mapa',
                                                  policialId: detalhe.policialId,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.isVisitorMode) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withAlpha(40),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.primaryLight.withAlpha(100)),
                                        ),
                                        child: const Text(
                                          'Contatos e mensagens ficam disponíveis após criar conta.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _requireAccount(
                                              () => _enviarMensagem(context, detalhe.policialId, false),
                                              message: 'Para enviar mensagens, crie sua conta ou faça login.',
                                            ),
                                            icon: const Icon(Icons.message, size: 18),
                                            label: const Text('Enviar Mensagem'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Builder(
                                            builder: (btnContext) {
                                              final jaSolicitado = _contatosSolicitados.contains(detalhe.policialId);
                                              return ElevatedButton.icon(
                                                onPressed: jaSolicitado
                                                    ? null
                                                    : () => _requireAccount(
                                                          () => _solicitarContato(
                                                            btnContext,
                                                            detalhe.policialId,
                                                            onUiUpdate: () => setModalState(() {}),
                                                          ),
                                                          message: 'Para solicitar contato, crie sua conta ou faça login.',
                                                        ),
                                                icon: Icon(jaSolicitado ? Icons.check_circle : Icons.person_add, size: 18),
                                                label: Text(jaSolicitado ? 'Contato Solicitado' : 'Solicitar Contato'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                  disabledBackgroundColor: const Color.fromARGB(255, 190, 190, 190),
                                                  disabledForegroundColor: const Color.fromARGB(255, 35, 35, 35),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Onde está:',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              detalhe.municipioAtual != null && detalhe.estadoAtual != null
                                                ? '${detalhe.municipioAtual}, ${detalhe.estadoAtual}'
                                                : detalhe.unidadeNome ?? 'Não informado',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            if (detalhe.unidadeNome != null)
                                              Text(
                                                detalhe.unidadeNome!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        detalheTipo == 'saindo' ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 20,
                                        color: detalheTipo == 'saindo' ? Colors.orange : Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detalheTipo == 'saindo' ? 'Quer sair para:' : 'Quer vir para:',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              detalhe.textoIntencao(
                                                tipo: detalheTipo,
                                                pontoNome: ponto.nome,
                                              ),
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(detalhe.forcaSigla),
                                    avatar: const Icon(Icons.shield, size: 18),
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
              },
            );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isVisitorMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.isVisitorMode) {
          context.go(AppRoutes.auth);
          return;
        }
        Navigator.of(context).pop();
      },
      child: Consumer<MapaProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.isVisitorMode ? 'Mapa (visitante)' : 'Mapa de Exploração'),
              leading: widget.isVisitorMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.go(AppRoutes.auth),
                    )
                  : null,
              actions: [
                IconButton(icon: const Icon(Icons.my_location), tooltip: 'Centralizar Mapa', onPressed: _resetMapView),
                IconButton(icon: const Icon(Icons.filter_alt), tooltip: 'Filtros', onPressed: () => _showFilterPanel(context)),
                if (!widget.isVisitorMode) ...AppBarHelper.adicionarBotaoRelatarProblema(context),
              ],
            ),
            body: _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(MapaProvider provider) {
    if (provider.shouldFitBounds && provider.pontosDoMapa.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBoundsToPontos(provider.pontosDoMapa);
        provider.clearFitBoundsFlag();
      });
    }

    if (provider.isInitialDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text('Erro: ${provider.errorMessage}'));
    }

    final markers = provider.markerViewData.map((item) {
      return Marker(
        key: ValueKey(item.ponto.municipioId),
        point: LatLng(item.ponto.latitude, item.ponto.longitude),
        width: 60, height: 60,
        child: GestureDetector(
          onTap: () => _showDetalhesModal(context, item.ponto),
          child: Container(
            decoration: BoxDecoration(
              color: _getMarkerColor(provider.tipoVisualizacao, item.ponto),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(child: Text(item.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(-14.2350, -51.9253),
            initialZoom: 4.5,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Desabilita rotação (trava norte)
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 80, size: const Size(50, 50),
                markers: markers,
                builder: (context, markers) {
                  final municipioIds = markers
                      .map((marker) => marker.key is ValueKey<int>
                          ? (marker.key as ValueKey<int>).value
                          : null)
                      .whereType<int>();
                  final totalIntencoes = provider.sumClusterValues(municipioIds);
                  return Container(
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    child: Center(child: Text(totalIntencoes.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  );
                },
              ),
            ),
          ],
        ),
        if (provider.isLoading) Container(color: Colors.black.withAlpha(102), child: const Center(child: CircularProgressIndicator())),
        _buildLegend(provider.tipoVisualizacao),
        if (widget.isVisitorMode)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.card.withAlpha(240),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(AppRoutes.auth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppTheme.primaryLight),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Crie sua conta pra ver contatos e participar de permutas',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.auth),
                        child: const Text('Criar conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _buildFilterContent(),
    );
  }

  Widget _buildFilterContent() {
    // Usamos um Consumer aqui para garantir que o conteúdo do modal também se reconstrua
    return Consumer<MapaProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 24),
              const Text('Tipo de Visualização', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  FilterChip(label: const Text('Saindo'), selected: provider.tipoVisualizacao == 'saindo', onSelected: (_) => provider.setTipoVisualizacao('saindo')),
                  FilterChip(label: const Text('Vindo'), selected: provider.tipoVisualizacao == 'vindo', onSelected: (_) => provider.setTipoVisualizacao('vindo')),
                  FilterChip(label: const Text('Balanço'), selected: provider.tipoVisualizacao == 'balanco', onSelected: (_) => provider.setTipoVisualizacao('balanco')),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int?>(
                initialValue: provider.estadoSelecionado,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todos os Estados')),
                  ...provider.estados.map((e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.sigla))),
                ],
                onChanged: (value) => provider.setEstado(value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: provider.forcaSelecionada,
                decoration: const InputDecoration(labelText: 'Força Policial', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todas as Forças')),
                  ...provider.forcas.map((f) => DropdownMenuItem<int?>(value: f.id, child: Text(f.sigla))),
                ],
                onChanged: (value) => provider.setForca(value),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => provider.limparFiltros(), child: const Text('Limpar Filtros'))),
            ],
          ),
        );
      },
    );
  }

  Color _getMarkerColor(String tipo, PontoMapa? ponto) {
    if (tipo == 'saindo') return Colors.redAccent;
    if (tipo == 'vindo') return Colors.blueAccent;
    if (tipo == 'balanco') return (ponto?.balanco ?? 0) >= 0 ? Colors.green : Colors.orange;
    return Colors.grey;
  }

  Widget _buildLegend(String tipo) {
    Widget legendContent;

    switch (tipo) {
      case 'saindo':
        legendContent = _buildLegendRow(
          icon: Icons.arrow_upward,
          color: Colors.redAccent,
          text: 'Policiais querendo sair do município',
        );
        break;
      case 'vindo':
        legendContent = _buildLegendRow(
          icon: Icons.arrow_downward,
          color: Colors.blueAccent,
          text: 'Policiais querendo entrar no município',
        );
        break;
      case 'balanco':
        legendContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendRow(
              icon: Icons.add_circle,
              color: Colors.green,
              text: 'Balanço positivo (mais entradas que saídas)',
            ),
            const SizedBox(height: 4),
            _buildLegendRow(
              icon: Icons.remove_circle,
              color: Colors.orange,
              text: 'Balanço negativo (mais saídas que entradas)',
            ),
          ],
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: legendContent,
          ),
        ),
      ),
    );
  }

  // Função auxiliar para construir as linhas da legenda
  Widget _buildLegendRow({required IconData icon, required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

// Função de preview para o Flutter Widget Preview
Widget previewMapaScreen() {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Exploração'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centralizar Mapa',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtros',
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mock do mapa - apenas um container colorido
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Mapa de Exploração',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preview simplificado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Mock de marcadores
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildMockMarker('5', Colors.redAccent, 'Saindo'),
                      _buildMockMarker('3', Colors.blueAccent, 'Vindo'),
                      _buildMockMarker('+2', Colors.green, 'Balanço'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Legenda mock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Policiais querendo sair do município',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper para criar marcadores mock
Widget _buildMockMarker(String label, Color color, String tooltip) {
  return Tooltip(
    message: tooltip,
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}
