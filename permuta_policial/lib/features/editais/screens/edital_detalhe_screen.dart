import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_router.dart';
import '../../../core/api/repositories/editais_repository.dart';
import '../../../core/models/edital_resumo.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/edital_simulador_provider.dart';
import '../widgets/edital_simulador_body.dart';
class EditalDetalheScreen extends StatefulWidget {
  final int editalId;

  const EditalDetalheScreen({super.key, required this.editalId});

  @override
  State<EditalDetalheScreen> createState() => _EditalDetalheScreenState();
}

class _EditalDetalheScreenState extends State<EditalDetalheScreen> {
  EditalDetalhe? _edital;
  bool _loading = true;
  String? _error;
  String? _whatsappNumero;
  bool _openingWhatsapp = false;

  @override
  void initState() {
    super.initState();
    _loadDetalhe();
    _loadWhatsappConfig();
  }

  String _mensagemSemAcesso(EditalDetalhe edital, bool precisaVerificacao) {
    if (precisaVerificacao) {
      return 'Para usar o simulador de escolha, é necessário ter a conta verificada como agente e constar na lista de participantes deste edital.';
    }
    if (edital.motivoSemAcesso == 'id_funcional_ausente') {
      return 'Seu perfil não possui ID funcional cadastrado. Atualize seus dados ou entre em contato com o suporte.';
    }
    return 'Sua conta já está verificada, mas seu ID funcional não foi encontrado na lista de participantes deste edital. Verifique se o ID cadastrado no perfil é o mesmo da lista.';
  }

  Future<void> _loadDetalhe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().refreshProfile();
      final repo = context.read<EditaisRepository>();
      final detalhe = await repo.getEdital(widget.editalId);
      if (!mounted) return;
      setState(() {
        _edital = detalhe;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadWhatsappConfig() async {
    try {
      final repo = context.read<EditaisRepository>();
      final config = await repo.getWhatsappConfig();
      if (!mounted) return;
      setState(() {
        _whatsappNumero = config['numero']?.toString() ?? '5551986200626';
      });
    } catch (_) {
      // Mantém fallback padrão
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Future<void> _openVerificacaoWhatsapp(EditalDetalhe edital) async {
    final user = context.read<AuthProvider>().user;
    final nome = (user?.nome.trim().isNotEmpty == true) ? user!.nome.trim() : 'agente';
    final idFuncional = (user?.idFuncional?.trim().isNotEmpty == true)
        ? user!.idFuncional!.trim()
        : 'não informado';
    final mensagem =
        'olá, sou $nome, ID $idFuncional e preciso verificar minha conta para acessar o edital ${edital.titulo}';
    final numero = (_whatsappNumero ?? '5551986200626').replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}');

    setState(() => _openingWhatsapp = true);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingWhatsapp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final edital = _edital;

    return Scaffold(
      appBar: AppBar(
        title: Text(edital?.titulo ?? 'Edital'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : edital == null
                  ? const Center(child: Text('Edital não encontrado'))
                  : edital.temAcesso
                      ? _buildComAcesso(context, edital)
                      : _buildSemAcesso(context, edital),
    );
  }

  Widget _buildHeaderBanner(EditalDetalhe edital) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edital.titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metaChip(Icons.shield_outlined, edital.forcaNome ?? edital.forcaSigla),
              _metaChip(Icons.category_outlined, edital.tipoLabel),
              _metaChip(Icons.event_outlined, edital.prazoLabel),
              if (edital.criterioLabel != null)
                _metaChip(Icons.military_tech_outlined, 'Critério: ${edital.criterioLabel}'),
              if (edital.minhaPosicao != null)
                _metaChip(Icons.emoji_events_outlined, 'Classificação: ${edital.minhaPosicao}º'),
            ],
          ),
          if (edital.resumo != null && edital.resumo!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(edital.resumo!),
          ],
          if (edital.linkPdf != null && edital.linkPdf!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openPdf(edital.linkPdf!),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Ver edital (PDF)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildComAcesso(BuildContext context, EditalDetalhe edital) {
    return ChangeNotifierProvider(
      create: (ctx) => EditalSimuladorProvider(ctx.read<EditaisRepository>(), edital.id)..loadDadosTela(),
      child: Consumer<EditalSimuladorProvider>(
        builder: (context, provider, _) => EditalSimuladorBody(
          provider: provider,
          header: _buildHeaderBanner(edital),
        ),
      ),
    );
  }

  Widget _buildSemAcesso(BuildContext context, EditalDetalhe edital) {
    final precisaVerificacao =
        edital.motivoSemAcesso == 'agente_nao_verificado' || !edital.agenteVerificado;

    return ListView(
      children: [
        _buildHeaderBanner(edital),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Card(
            color: const Color(0xFFFFF3CD),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFFECB5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Color(0xFF856404)),
                  const SizedBox(height: 16),
                  Text(
                    'Simulador indisponível',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF664D03),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _mensagemSemAcesso(edital, precisaVerificacao),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF664D03),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (precisaVerificacao) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final verified = await context.push<bool>(
                            '${AppRoutes.verificacaoBarreira}?'
                            'titulo=${Uri.encodeComponent('Verificação necessária para Editais')}'
                            '&descricao=${Uri.encodeComponent('Para acessar simuladores de editais, verifique sua conta como agente policial.')}'
                            '&contexto=${Uri.encodeComponent('acessar o edital ${edital.titulo}')}',
                          );
                          if (verified == true) _loadDetalhe();
                        },
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Verificar conta com funcional ou contracheque'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openingWhatsapp ? null : () => _openVerificacaoWhatsapp(edital),
                      child: Text(
                        _openingWhatsapp ? 'Abrindo WhatsApp...' : 'Prefiro verificação manual via WhatsApp',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
