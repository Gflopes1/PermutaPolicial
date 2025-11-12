// /lib/features/profile/screens/meus_dados_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/constants/app_constants.dart';
import 'package:permuta_policial/shared/widgets/custom_text_field.dart';
import 'package:permuta_policial/shared/widgets/custom_dropdown_search.dart';
import 'package:permuta_policial/shared/widgets/error_display_widget.dart';
import 'package:permuta_policial/shared/widgets/loading_widget.dart';
import 'package:permuta_policial/core/utils/error_message_helper.dart';
import 'package:permuta_policial/core/api/api_exception.dart';
import 'package:permuta_policial/core/api/repositories/dados_repository.dart';
import '../providers/profile_provider.dart';

class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _qsoController = TextEditingController();
  final _antiguidadeController = TextEditingController();

  int? _selectedForcaId;
  int? _selectedPostoId;
  dynamic _selectedForca;
  dynamic _selectedPosto;
  List<dynamic> _postosCache = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    await provider.loadProfile();

    if (provider.userProfile != null) {
      final profile = provider.userProfile!;
      _nomeController.text = profile.nome;
      _emailController.text = profile.email ?? '';
      _qsoController.text = profile.qso ?? '';
      _antiguidadeController.text = profile.antiguidade ?? '';
      _selectedForcaId = profile.forcaId;
      _selectedPostoId = profile.postoGraduacaoId;

      // Carregar força e posto
      if (_selectedForcaId != null) {
        final forcas = await provider.getForcas();
        if (!mounted) return;
        _selectedForca = forcas.firstWhere(
          (f) => f.id == _selectedForcaId,
          orElse: () => null,
        );
        if (_selectedForca != null && _selectedForca.tipoPermuta != null) {
          _postosCache = await dadosRepo.getPostosPorForca(_selectedForca.tipoPermuta);
          if (!mounted) return;
          if (_selectedPostoId != null) {
            _selectedPosto = _postosCache.firstWhere(
              (p) => p.id == _selectedPostoId,
              orElse: () => null,
            );
          }
        }
      }

      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final payload = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'qso': _qsoController.text.trim(),
      if (_antiguidadeController.text.trim().isNotEmpty)
        'antiguidade': _antiguidadeController.text.trim(),
      if (_selectedForcaId != null) 'forca_id': _selectedForcaId,
      if (_selectedPostoId != null) 'posto_graduacao_id': _selectedPostoId,
    };

    try {
      final success = await provider.updateProfile(payload);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyMessage(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Dados'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userProfile == null) {
            return const LoadingWidget(message: 'Carregando dados...');
          }

          if (provider.errorMessage != null && provider.userProfile == null) {
            return ErrorDisplayWidget(
              customMessage: provider.errorMessage!,
              customTitle: 'Erro ao carregar dados',
              onRetry: () => provider.loadProfile(),
            );
          }

          final profile = provider.userProfile;
          if (profile == null) {
            return const Center(child: Text('Não foi possível carregar os dados'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: AppConstants.cardElevation,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Pessoais',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          // ID Funcional (somente leitura)
                          TextFormField(
                            initialValue: profile.idFuncional ?? 'Não informado',
                            decoration: const InputDecoration(
                              labelText: 'ID Funcional',
                              prefixIcon: Icon(Icons.badge),
                              filled: true,
                              enabled: false,
                              helperText: 'ID Funcional não pode ser alterado',
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          CustomTextField(
                            controller: _nomeController,
                            label: 'Nome Completo *',
                            prefixIcon: Icons.person,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Nome é obrigatório' : null,
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email *',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Email é obrigatório';
                              if (!v!.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          CustomTextField(
                            controller: _qsoController,
                            label: 'QSO / Telefone *',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'QSO é obrigatório' : null,
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          CustomTextField(
                            controller: _antiguidadeController,
                            label: 'Antiguidade',
                            prefixIcon: Icons.calendar_today,
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMD),
                  Card(
                    elevation: AppConstants.cardElevation,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Profissionais',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          Consumer<ProfileProvider>(
                            builder: (context, provider, child) {
                              return CustomDropdownSearch<dynamic>(
                                label: 'Força Policial',
                                asyncItems: (_) => provider.getForcas(),
                                itemAsString: (item) => '${item.sigla} - ${item.nome}',
                                selectedItem: _selectedForca,
                                onChanged: (value) async {
                                  setState(() {
                                    _selectedForca = value;
                                    _selectedForcaId = value?.id;
                                    _selectedPosto = null;
                                    _selectedPostoId = null;
                                    _postosCache = [];
                                  });

                                  if (value != null && value.tipoPermuta != null) {
                                    final dadosRepo = Provider.of<DadosRepository>(
                                      context,
                                      listen: false,
                                    );
                                    final postos = await dadosRepo.getPostosPorForca(value.tipoPermuta);
                                    setState(() {
                                      _postosCache = postos;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          if (_postosCache.isNotEmpty)
                            CustomDropdownSearch<dynamic>(
                              label: 'Posto/Graduação',
                              items: _postosCache,
                              itemAsString: (item) => item.nome ?? item.toString(),
                              selectedItem: _selectedPosto,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPosto = value;
                                  _selectedPostoId = value?.id;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _salvarDados,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Salvando...' : 'Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

