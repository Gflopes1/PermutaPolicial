// /lib/features/profile/screens/meus_dados_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/intencao.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/api/api_exception.dart';
import '../widgets/gerir_intencoes_modal.dart';
import '../widgets/edit_lotacao_modal.dart';

class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _qsoController;
  late TextEditingController _antiguidadeController;
  bool _isSaving = false;
  UserProfile? _userProfile;
  List<Intencao> _intencoes = [];
  bool _ocultarNoMapa = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    _userProfile = provider.userData;
    _intencoes = provider.intencoes;
    _emailController = TextEditingController(text: _userProfile?.email ?? '');
    _qsoController = TextEditingController(text: _userProfile?.qso ?? '');
    _antiguidadeController = TextEditingController(text: _userProfile?.antiguidade ?? '');
    _ocultarNoMapa = _userProfile?.ocultarNoMapa ?? false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final updateData = <String, dynamic>{};

      if (_emailController.text != _userProfile?.email) {
        updateData['email'] = _emailController.text;
      }
      if (_qsoController.text != _userProfile?.qso) {
        updateData['qso'] = _qsoController.text;
      }
      if (_antiguidadeController.text != _userProfile?.antiguidade) {
        updateData['antiguidade'] = _antiguidadeController.text;
      }
      if (_ocultarNoMapa != (_userProfile?.ocultarNoMapa ?? false)) {
        updateData['ocultar_no_mapa'] = _ocultarNoMapa;
      }

      if (updateData.isNotEmpty) {
        final success = await dashboardProvider.updateProfile(updateData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados atualizados com sucesso!')),
          );
          // Atualiza o perfil local
          await dashboardProvider.fetchInitialData();
          setState(() {
            _userProfile = dashboardProvider.userData;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma alteração foi feita.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String message = 'Erro ao salvar dados.';
        if (e is ApiException) {
          message = e.userMessage;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Meus Dados')),
          body: const Center(child: Text('Erro ao carregar dados do usuário.')),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Volta para a tela anterior
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Meus Dados')),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('Nome', _userProfile!.nome),
              const SizedBox(height: 16),
              _buildReadOnlyField('ID Funcional', _userProfile!.idFuncional ?? 'Não informado'),
              const SizedBox(height: 16),
              _buildReadOnlyField('Força', _userProfile!.forcaSigla ?? 'Não informado'),
              const SizedBox(height: 16),
              _buildReadOnlyField('Posto/Graduação', _userProfile!.postoGraduacaoNome ?? 'Não informado'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                  showDialog(
                    context: context,
                    builder: (ctx) => ChangeNotifierProvider.value(
                      value: dashboardProvider,
                      child: EditLotacaoModal(userProfile: _userProfile!),
                    ),
                  ).then((_) {
                    // Recarrega os dados após fechar o modal
                    dashboardProvider.fetchInitialData().then((_) {
                      if (mounted) {
                        setState(() {
                          _userProfile = dashboardProvider.userData;
                        });
                      }
                    });
                  });
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Alterar minha lotação'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email é obrigatório';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qsoController,
                decoration: const InputDecoration(
                  labelText: 'QSO (Telefone)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _antiguidadeController,
                decoration: const InputDecoration(
                  labelText: 'Antiguidade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Não desejo aparecer no mapa de intenções ou enviar meu contato automaticamente quando fechar uma permuta'),
                subtitle: const Text('Mais privacidade, menos chance de encontrar uma permuta'),
                value: _ocultarNoMapa,
                onChanged: (value) => setState(() => _ocultarNoMapa = value ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Intenções de Permuta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_intencoes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma intenção cadastrada.'),
                  ),
                )
              else
                ..._intencoes.map((intencao) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(intencao.prioridade.toString()),
                    ),
                    title: Text(_getIntencaoDescricao(intencao)),
                    subtitle: Text('Prioridade ${intencao.prioridade}'),
                  ),
                )),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                  showDialog(
                    context: context,
                    builder: (ctx) => ChangeNotifierProvider.value(
                      value: dashboardProvider,
                      child: const GerirIntencoesModal(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Gerenciar Intenções'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  String _getIntencaoDescricao(Intencao intencao) {
    switch (intencao.tipoIntencao) {
      case 'UNIDADE':
        return 'Unidade: ${intencao.unidadeNome ?? 'N/A'}';
      case 'MUNICIPIO':
        return 'Município: ${intencao.municipioNome ?? 'N/A'}';
      case 'ESTADO':
        return 'Estado: ${intencao.estadoSigla ?? 'N/A'}';
      default:
        return 'Tipo desconhecido';
    }
  }
}

