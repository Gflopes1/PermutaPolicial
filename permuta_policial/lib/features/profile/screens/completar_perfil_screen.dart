// /lib/features/profile/screens/completar_perfil_screen.dart

import 'package:flutter/material.dart';
import 'package:permuta_policial/core/utils/error_handler.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/models/forca_policial.dart';
import '../../../core/models/posto_graduacao.dart';
import '../widgets/sugerir_unidade_modal.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/api/api_exception.dart';

class CompletarPerfilScreen extends StatefulWidget {
  const CompletarPerfilScreen({super.key});
  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  // Controllers para os campos de texto
  final _idFuncionalController = TextEditingController();
  final _qsoController = TextEditingController();
  final _antiguidadeController = TextEditingController();

  // Variáveis para os dropdowns
  int? _selectedForcaId;
  ForcaPolicial? _initialForca;
  int? _selectedEstadoId;
  int? _selectedMunicipioId;
  int? _selectedUnidadeId;
  int? _selectedPostoId;
  List<PostoGraduacao> _postosCache = [];
  bool _isLoadingPostos = false;
  late bool _isInterestadual = false;
  late bool _ocultarNoMapa = false;

  final _municipioKey = GlobalKey<DropdownSearchState<dynamic>>();
  final _unidadeKey = GlobalKey<DropdownSearchState<dynamic>>();
  
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    provider.loadProfile().then((_) async {
      if (provider.userProfile != null) {
        // Popula os campos com dados existentes
        _idFuncionalController.text = provider.userProfile!.idFuncional ?? '';
        _qsoController.text = provider.userProfile!.qso ?? '';
        _antiguidadeController.text = provider.userProfile!.antiguidade ?? '';
        _isInterestadual = provider.userProfile!.lotacaoInterestadual;
        _ocultarNoMapa = provider.userProfile!.ocultarNoMapa ?? false;

        if (provider.userProfile!.forcaId != null) {
          _selectedForcaId = provider.userProfile!.forcaId;
          _selectedPostoId = provider.userProfile!.postoGraduacaoId;
          final forcas = await provider.getForcas();
          if (mounted) {
            ForcaPolicial? initialForca;
            for (final f in forcas) {
              if (f is ForcaPolicial && f.id == _selectedForcaId) {
                initialForca = f;
                break;
              }
            }
            setState(() => _initialForca = initialForca);
            await _loadPostosForForca(provider);
          }
        }
        if (mounted) setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _idFuncionalController.dispose();
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    // Validação dos campos obrigatórios (unidade agora é opcional)
    if (_idFuncionalController.text.trim().isEmpty || 
        _qsoController.text.trim().isEmpty || 
        _selectedForcaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Por favor, preencha todos os campos obrigatórios.'),
      );
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Validação: deve ter pelo menos município ou unidade
    if (_selectedMunicipioId == null && _selectedUnidadeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Por favor, selecione pelo menos um município ou uma unidade.'),
      );
      return;
    }

    if (_selectedPostoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Selecione seu posto/graduação.'),
      );
      return;
    }

    // Payload agora inclui o campo de antiguidade e ocultar_no_mapa
    final payload = <String, dynamic>{
      'id_funcional': _idFuncionalController.text.trim(),
      'qso': _qsoController.text.trim(),
      'antiguidade': _antiguidadeController.text.trim(),
      'forca_id': _selectedForcaId!,
      'posto_graduacao_id': _selectedPostoId!,
      'lotacao_interestadual': _isInterestadual,
      'ocultar_no_mapa': _ocultarNoMapa,
    };
    
    // Lógica para unidade_atual_id e municipio_id:
    // - Se uma unidade foi selecionada, inclui no payload
    // - Se o município foi selecionado mas não a unidade, envia municipio_id
    if (_selectedUnidadeId != null) {
      payload['unidade_atual_id'] = _selectedUnidadeId;
    } else if (_selectedMunicipioId != null) {
      // Município selecionado sem unidade: envia municipio_id para backend
      payload['municipio_id'] = _selectedMunicipioId;
      payload['unidade_atual_id'] = null;
    }

    try {
      final success = await provider.updateProfile(payload);
      
      if (!mounted) return;
      
      if (success) {
        await context.read<AuthProvider>().refreshProfile();
        try {
          await context.read<DashboardProvider>().fetchInitialData();
        } catch (_) {}
        if (!mounted) return;
        context.go(AppRoutes.dashboard);
      } else {
        // Mostra mensagem de erro específica ou genérica
        String errorMessage = 'Erro ao salvar perfil.';
        
        if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty) {
          errorMessage = provider.errorMessage!;
        } else {
          errorMessage = 'Erro inesperado ao salvar perfil. Se você acredita que isso é um erro, entre em contato com o suporte.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(errorMessage),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Captura erros não tratados pelo provider
      String errorMessage = 'Erro inesperado ao salvar perfil. Se você acredita que isso é um erro, entre em contato com o suporte.';
      
      // Tenta extrair mensagem específica do erro
      if (e is ApiException) {
        errorMessage = e.userMessage;
      } else {
        // Usa ErrorHandler para tentar obter mensagem melhor
        final handlerMessage = ErrorHandler.getErrorMessage(e);
        if (handlerMessage.isNotEmpty && !handlerMessage.contains('Ocorreu um erro inesperado')) {
          errorMessage = handlerMessage;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(errorMessage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppStyles.card(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.userProfile == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.errorMessage != null) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erro: ${provider.errorMessage}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadProfile(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    );
                  }
                  if (provider.userProfile == null) {
                    return const Center(child: Text('Não foi possível carregar os dados do perfil.'));
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.edit_location_alt_outlined, size: 50, color: AppTheme.primary),
                      AppStyles.spacingSmall,
                      Text(
                        'Bem-vindo(a), ${provider.userProfile!.nome}!',
                        style: AppStyles.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      AppStyles.spacingSmall,
                      Text(
                        'Para encontrar as melhores combinações, precisamos de algumas informações.',
                        style: AppStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 32),
                      _buildFormulario(provider),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPostosForForca(ProfileProvider provider) async {
    if (_selectedForcaId == null || _initialForca == null) return;
    if (_initialForca!.tipoPermuta.isEmpty) return;
    setState(() => _isLoadingPostos = true);
    try {
      final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
      final postos = await dadosRepo.getPostosPorForca(_initialForca!.tipoPermuta);
      if (mounted) {
        setState(() {
          _postosCache = postos;
          if (_selectedPostoId != null &&
              !postos.any((p) => p.id == _selectedPostoId)) {
            _selectedPostoId = null;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPostos = false);
    }
  }

  PostoGraduacao? _selectedPosto() {
    if (_selectedPostoId == null) return null;
    for (final p in _postosCache) {
      if (p.id == _selectedPostoId) return p;
    }
    return null;
  }

  Widget _buildFormulario(ProfileProvider provider) {
    // Lógica de bloqueio agora é APENAS para o ID Funcional.
    bool canEditIdField = provider.userProfile?.idFuncional == null || provider.userProfile!.idFuncional!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Sua Identificação", style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        
        CustomTextField(
          controller: _idFuncionalController,
          label: 'ID Funcional / Matrícula',
          prefixIcon: Icons.badge,
          enabled: canEditIdField, // Lógica de bloqueio aplicada APENAS aqui.
        ),
        const SizedBox(height: 20),
        
        CustomTextField(
          controller: _qsoController,
          label: 'Telefone / QSO (com DDD)',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          // Propriedade 'enabled' removida para ser sempre editável, pois o padrão é 'true'[cite: 24, 25].
        ),
        const SizedBox(height: 20),

        CustomDropdownSearch<dynamic>(
          label: "Força Policial",
          // Propriedade 'enabled' removida para ser sempre editável, pois o padrão é 'true'[cite: 13, 15].
          selectedItem: _initialForca,
          asyncItems: (_) => provider.getForcas(),
          itemAsString: (dynamic f) => "${f.sigla} - ${f.nome}",
          onChanged: (dynamic data) async {
            setState(() {
              _selectedForcaId = data?.id;
              _initialForca = data is ForcaPolicial ? data : null;
              _selectedPostoId = null;
              _selectedUnidadeId = null;
              _unidadeKey.currentState?.clear();
            });
            if (_initialForca != null) {
              await _loadPostosForForca(provider);
            }
          },
        ),
        const SizedBox(height: 20),

        CustomDropdownSearch<PostoGraduacao>(
          label: 'Posto / Graduação / Cargo',
          enabled: !_isLoadingPostos && _selectedForcaId != null && _postosCache.isNotEmpty,
          selectedItem: _selectedPosto(),
          items: _postosCache,
          itemAsString: (p) => p.nome,
          onChanged: (posto) => setState(() => _selectedPostoId = posto?.id),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _antiguidadeController,
          label: 'Antiguidade (Ex: Turma 2018 - Opcional)',
          prefixIcon: Icons.military_tech,
        ),
        const Divider(height: 32),
        Text("Sua Lotação Atual", style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        
        CustomDropdownSearch<dynamic>(
          label: "Estado",
          asyncItems: (_) => provider.getEstados(),
          itemAsString: (dynamic u) => u.sigla,
          onChanged: (dynamic data) {
            setState(() {
              _selectedEstadoId = data?.id;
              _selectedMunicipioId = null;
              _selectedUnidadeId = null;
              _municipioKey.currentState?.clear();
              _unidadeKey.currentState?.clear();
            });
          },
        ),
        const SizedBox(height: 20),

        CustomDropdownSearch<dynamic>(
          key: _municipioKey,
          enabled: _selectedEstadoId != null,
          label: "Município",
          asyncItems: (_) => provider.getMunicipios(_selectedEstadoId!),
          itemAsString: (dynamic u) => u.nome,
          onChanged: (dynamic data) {
            setState(() {
              _selectedMunicipioId = data?.id;
              _selectedUnidadeId = null;
              _unidadeKey.currentState?.clear();
            });
          },
        ),
        const SizedBox(height: 20),
        
        CustomDropdownSearch<dynamic>(
          key: _unidadeKey,
          enabled: _selectedMunicipioId != null && _selectedForcaId != null,
          label: "Unidade (Opcional)",
          asyncItems: (_) => provider.getUnidades(municipioId: _selectedMunicipioId!, forcaId: _selectedForcaId!),
          itemAsString: (dynamic u) => u.nome,
          onChanged: (dynamic data) => setState(() => _selectedUnidadeId = data?.id),
        ),
        const SizedBox(height: 8),
        // Botão para sugerir unidade
        if (_selectedMunicipioId != null && _selectedForcaId != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => SugerirUnidadeModal(
                    municipioId: _selectedMunicipioId!,
                    forcaId: _selectedForcaId!,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Não encontrou sua unidade? Sugira'),
            ),
          ),
        const SizedBox(height: 10),

        CheckboxListTile(
          title: const Text('Aceito permuta interestadual'),
          value: _isInterestadual,
          onChanged: (value) => setState(() => _isInterestadual = value ?? false),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Não desejo aparecer no mapa de intenções ou enviar meu contato automaticamente quando fechar uma permuta'),
          subtitle: const Text('Mais privacidade, menos chance de encontrar uma permuta'),
          value: _ocultarNoMapa,
          onChanged: (value) => setState(() => _ocultarNoMapa = value ?? false),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: provider.isLoading ? null : _salvarPerfil,
          style: AppStyles.primaryButton,
          child: provider.isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Salvar e Continuar'),
        ),
      ],
    );
  }
}