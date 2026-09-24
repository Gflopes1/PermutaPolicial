import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories/editais_repository.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../auth/utils/oauth_helpers.dart';

/// Landing pública de um edital: sem login, serve como vitrine do site.
class EditalConsultaVisitanteScreen extends StatefulWidget {
  final int editalId;

  const EditalConsultaVisitanteScreen({super.key, required this.editalId});

  @override
  State<EditalConsultaVisitanteScreen> createState() =>
      _EditalConsultaVisitanteScreenState();
}

class _EditalConsultaVisitanteScreenState
    extends State<EditalConsultaVisitanteScreen> {
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loadingResumo = true;
  String? _resumoError;
  Map<String, dynamic>? _edital;
  Map<String, dynamic>? _estatisticas;

  bool _consultando = false;
  String? _error;
  Map<String, dynamic>? _resultado;

  @override
  void initState() {
    super.initState();
    _loadResumo();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _loadResumo() async {
    setState(() {
      _loadingResumo = true;
      _resumoError = null;
    });
    try {
      final data = await context.read<EditaisRepository>().resumoPublico(widget.editalId);
      if (!mounted) return;
      setState(() {
        _edital = Map<String, dynamic>.from(data['edital'] as Map);
        _estatisticas = Map<String, dynamic>.from(data['estatisticas'] as Map);
        _loadingResumo = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _resumoError = e.message;
        _loadingResumo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resumoError = 'Não foi possível carregar este edital.';
        _loadingResumo = false;
      });
    }
  }

  Future<void> _consultar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _consultando = true;
      _error = null;
      _resultado = null;
    });
    try {
      final data = await context.read<EditaisRepository>().consultaPublica(
            widget.editalId,
            _idController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _resultado = data;
        _consultando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _consultando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível consultar. Tente novamente.';
        _consultando = false;
      });
    }
  }

  Future<void> _inscricaoRapida() async {
    final idFuncional =
        (_resultado?['id_funcional'] ?? _idController.text).toString().trim();
    await OAuthHelpers.loginWithMicrosoft(
      context,
      idFuncional: idFuncional.isEmpty ? null : idFuncional,
      editalId: widget.editalId,
      returnTo: '/editais/${widget.editalId}',
    );
  }

  Future<void> _copiarLink() async {
    final link = '${Uri.base.origin}/edital/${widget.editalId}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppStyles.successSnackBar('Link copiado: $link'),
    );
  }

  String get _prazoLabel {
    final raw = _edital?['data_encerramento']?.toString();
    final data = raw == null ? null : DateTime.tryParse(raw);
    if (data == null) return 'Prazo não informado';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return 'Inscrições até $dia/$mes/${data.year}';
  }

  String get _tipoLabel =>
      _edital?['tipo'] == 'TRANSFERENCIA_INTERNA' ? 'Transferência interna' : 'Formação';

  @override
  Widget build(BuildContext context) {
    return AppStyles.gradientScaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildBrandLogo(size: 32),
            const SizedBox(width: 10),
            Text('Permuta Policial', style: AppStyles.titleSmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.auth),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Entrar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loadingResumo
          ? const Center(child: AppStyles.defaultLoader)
          : _resumoError != null
              ? _buildErroResumo()
              : _buildLanding(),
    );
  }

  Widget _buildErroResumo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(_resumoError!, textAlign: TextAlign.center, style: AppStyles.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              style: AppStyles.primaryButton,
              onPressed: _loadResumo,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanding() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 32 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(isWide),
                  const SizedBox(height: 24),
                  _buildEstatisticas(isWide),
                  const SizedBox(height: 24),
                  _buildConsultaCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildErroConsulta(),
                  ],
                  if (_resultado != null) ...[
                    const SizedBox(height: 24),
                    _buildResultado(isWide),
                  ],
                  const SizedBox(height: 32),
                  _buildCta(),
                  const SizedBox(height: 24),
                  _buildRodape(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandLogo({double size = 72}) {
    return Image.asset(
      'assets/images/ic_launcher.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildHero(bool isWide) {
    final aberto = _edital?['status'] == 'ABERTO';
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLG),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandLogo(size: 88),
                const SizedBox(width: 20),
                Expanded(child: _buildHeroHeaderContent(aberto, isWide: true)),
              ],
            )
          else ...[
            Center(child: _buildBrandLogo(size: 72)),
            const SizedBox(height: 16),
            _buildHeroHeaderContent(aberto),
          ],
          const SizedBox(height: 16),
          Text(
            'Consulte sua classificação e veja quantos candidatos já demonstraram '
            'interesse em cada cidade — de graça e sem criar conta.',
            style: AppStyles.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          if ((_edital?['resumo']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_edital!['resumo'].toString(), style: AppStyles.bodySmall),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _infoLinha(Icons.event_outlined, _prazoLabel),
              if (_edital?['criterio_label'] != null)
                _infoLinha(Icons.military_tech_outlined, 'Critério: ${_edital!['criterio_label']}'),
              if (_edital?['forca_nome'] != null)
                _infoLinha(Icons.shield_outlined, _edital!['forca_nome'].toString()),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: AppStyles.outlinedButton,
                onPressed: _copiarLink,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copiar link desta página'),
              ),
              if ((_edital?['link_pdf']?.toString() ?? '').isNotEmpty)
                OutlinedButton.icon(
                  style: AppStyles.outlinedButton,
                  onPressed: () => OAuthHelpers.launchExternal(
                    context,
                    _edital!['link_pdf'].toString(),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Ver edital oficial'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderContent(bool aberto, {bool isWide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(
              aberto ? 'Edital aberto' : 'Edital encerrado',
              color: aberto ? AppTheme.success : Colors.grey,
            ),
            _badge(_edital?['forca_sigla']?.toString() ?? '', color: AppTheme.primaryLight),
            _badge(_tipoLabel, color: AppTheme.primaryLight),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _edital?['titulo']?.toString() ?? 'Edital',
          style: TextStyle(
            fontSize: isWide ? 38 : 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _buildEstatisticas(bool isWide) {
    final stats = _estatisticas ?? const {};
    final itens = [
      _StatData('Vagas ofertadas', '${stats['total_vagas'] ?? 0}', Icons.inventory_2_outlined),
      _StatData('Cidades / OPMs', '${stats['total_unidades'] ?? 0}', Icons.location_city_outlined),
      _StatData('Candidatos na lista', '${stats['total_participantes'] ?? 0}', Icons.groups_outlined),
      _StatData('Intenções registradas', '${stats['total_intencoes'] ?? 0}', Icons.how_to_vote_outlined),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: itens
          .map((item) => SizedBox(
                width: isWide ? 208 : (MediaQuery.of(context).size.width - 44) / 2,
                child: _statCard(item),
              ))
          .toList(),
    );
  }

  Widget _statCard(_StatData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMD),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: AppTheme.primaryLight, size: 22),
          const SizedBox(height: 10),
          Text(
            item.valor,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(item.label, style: AppStyles.caption),
        ],
      ),
    );
  }

  Widget _buildConsultaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLG),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Veja sua posição agora', style: AppStyles.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Digite seu ID funcional. Mostramos apenas a sua classificação e os totais '
            'de interessados por cidade — nunca a antiguidade de outros candidatos.',
            style: AppStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Seu ID funcional',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _consultar(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o ID funcional' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: AppStyles.primaryButton,
                    onPressed: _consultando ? null : _consultar,
                    child: _consultando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Consultar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErroConsulta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMD),
        border: Border.all(color: AppTheme.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: AppStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildResultado(bool isWide) {
    final minhasEscolhas = (_resultado?['minhas_escolhas'] as List?) ?? const [];
    final cidades = (_resultado?['cidades'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
            ),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusLG),
          ),
          child: Column(
            children: [
              Text('Sua classificação neste edital', style: AppStyles.bodySmall.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                '${_resultado!['classificacao']}º',
                style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text('ID ${_resultado!['id_funcional']}', style: AppStyles.caption.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        if (minhasEscolhas.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Cidades que você já escolheu', style: AppStyles.titleSmall),
          const SizedBox(height: 8),
          ...minhasEscolhas.map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            return _cidadeTile(
              titulo: item['opm']?.toString() ?? 'OPM',
              subtitle: [
                if (item['crpm'] != null) item['crpm'].toString(),
                if (item['unidade_nome'] != null) item['unidade_nome'].toString(),
                'Sua ${item['opcao']}ª opção',
              ].where((e) => e.isNotEmpty).join(' · '),
              inscritos: (item['total_inscritos'] as num?)?.toInt() ?? 0,
              destaque: true,
            );
          }),
        ],
        const SizedBox(height: 20),
        Text('Interessados por cidade / OPM', style: AppStyles.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Quantidade de candidatos que registraram intenção em cada opção.',
          style: AppStyles.caption,
        ),
        const SizedBox(height: 8),
        ...cidades.map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          return _cidadeTile(
            titulo: item['opm']?.toString() ?? 'OPM',
            subtitle: [
              if (item['crpm'] != null) item['crpm'].toString(),
              if (item['unidade_nome'] != null) item['unidade_nome'].toString(),
              '${item['vagas_disponiveis'] ?? 0} vagas',
            ].where((e) => e.toString().isNotEmpty).join(' · '),
            inscritos: (item['total_inscritos'] as num?)?.toInt() ?? 0,
          );
        }),
      ],
    );
  }

  Widget _cidadeTile({
    required String titulo,
    required String subtitle,
    required int inscritos,
    bool destaque = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: destaque ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.card,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMD),
        border: Border.all(color: destaque ? AppTheme.success : Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '$inscritos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: destaque ? AppTheme.success : Colors.white,
                ),
              ),
              Text('interessados', style: AppStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLG),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Simule sua escolha antes de decidir', style: AppStyles.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Com uma conta você monta suas 3 opções e vê, em tempo real, quantos candidatos '
            'mais antigos e mais modernos disputam a mesma vaga.',
            style: AppStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          _beneficio(Icons.insights_outlined, 'Simulador de vagas com análise de concorrência'),
          _beneficio(Icons.swap_horiz, 'Busca de permutas diretas, triangulares e em ciclo'),
          _beneficio(Icons.map_outlined, 'Mapa tático e alertas de novos matches'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: AppStyles.primaryButton,
            onPressed: _inscricaoRapida,
            icon: const Icon(Icons.login),
            label: const Text('Entrar com Microsoft (.gov.br)'),
          ),
          const SizedBox(height: 8),
          Text(
            'Inscrição rápida: com e-mail institucional .gov.br sua conta já entra verificada, '
            'sem preencher o restante do perfil agora.',
            style: AppStyles.caption,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.auth),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Prefiro criar conta com e-mail e senha'),
          ),
        ],
      ),
    );
  }

  Widget _beneficio(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryLight),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: AppStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildRodape() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Esta página não exibe nomes, antiguidade ou dados pessoais de outros candidatos. '
            'Apenas totais agregados por cidade.',
            style: AppStyles.caption,
          ),
        ),
      ],
    );
  }

  Widget _badge(String texto, {required Color color}) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoLinha(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Text(texto, style: AppStyles.bodySmall),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String valor;
  final IconData icon;

  const _StatData(this.label, this.valor, this.icon);
}
