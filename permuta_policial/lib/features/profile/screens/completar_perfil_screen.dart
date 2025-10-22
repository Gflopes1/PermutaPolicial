// /lib/features/profile/screens/completar_perfil_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../providers/profile_provider.dart';
import '../../../core/config/app_routes.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/models/forca_policial.dart';

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
  late bool _isInterestadual = false;

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

        if (provider.userProfile!.forcaId != null) {
          _selectedForcaId = provider.userProfile!.forcaId;
          final forcas = await provider.getForcas();
          if (mounted) {
            setState(() {
              _initialForca = forcas.firstWhere(
                (f) => f.id == _selectedForcaId, 
                orElse: () => null
              );
            });
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
    // Validação dos campos obrigatórios
    if (_idFuncionalController.text.trim().isEmpty || 
        _qsoController.text.trim().isEmpty || 
        _selectedForcaId == null || 
        _selectedUnidadeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    
    // Payload agora inclui o campo de antiguidade
    final payload = {
      'id_funcional': _idFuncionalController.text.trim(),
      'qso': _qsoController.text.trim(),
      'antiguidade': _antiguidadeController.text.trim(),
      'forca_id': _selectedForcaId!,
      'unidade_atual_id': _selectedUnidadeId!,
      'lotacao_interestadual': _isInterestadual,
    };

    final success = await provider.updateProfile(payload);
    
    if (success && mounted) {
      navigator.pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Consumer<ProfileProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.userProfile == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null) {
                      return Center(child: Text('Erro: ${provider.errorMessage}'));
                    }
                    if (provider.userProfile == null) {
                      return const Center(child: Text('Não foi possível carregar os dados do perfil.'));
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.edit_location_alt_outlined, size: 50, color: Colors.blueAccent),
                        const SizedBox(height: 16),
                        Text('Bem-vindo(a), ${provider.userProfile!.nome}!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text('Para encontrar as melhores combinações, precisamos de algumas informações.', textAlign: TextAlign.center),
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
      ),
    );
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
          onChanged: (dynamic data) {
            setState(() {
              _selectedForcaId = data?.id;
              // Limpa os campos de unidade se a força for alterada
              _selectedUnidadeId = null;
              _unidadeKey.currentState?.clear();
            });
          },
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
          label: "Unidade",
          asyncItems: (_) => provider.getUnidades(municipioId: _selectedMunicipioId!, forcaId: _selectedForcaId!),
          itemAsString: (dynamic u) => u.nome,
          onChanged: (dynamic data) => setState(() => _selectedUnidadeId = data?.id),
        ),
        const SizedBox(height: 10),

        CheckboxListTile(
          title: const Text('Aceito permuta interestadual'),
          value: _isInterestadual,
          onChanged: (value) => setState(() => _isInterestadual = value ?? false),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: provider.isLoading ? null : _salvarPerfil,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: provider.isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Salvar e Continuar'),
        ),
      ],
    );
  }
}