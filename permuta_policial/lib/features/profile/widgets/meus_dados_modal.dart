// /lib/features/profile/widgets/meus_dados_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/intencao.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/api/api_exception.dart';
import 'gerir_intencoes_modal.dart';

class MeusDadosModal extends StatefulWidget {
  final UserProfile userProfile;
  final List<Intencao> intencoes;

  const MeusDadosModal({
    super.key,
    required this.userProfile,
    required this.intencoes,
  });

  @override
  State<MeusDadosModal> createState() => _MeusDadosModalState();
}

class _MeusDadosModalState extends State<MeusDadosModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _qsoController;
  late TextEditingController _antiguidadeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userProfile.email ?? '');
    _qsoController = TextEditingController(text: widget.userProfile.qso ?? '');
    _antiguidadeController = TextEditingController(text: widget.userProfile.antiguidade ?? '');
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

      if (_emailController.text != widget.userProfile.email) {
        updateData['email'] = _emailController.text;
      }
      if (_qsoController.text != widget.userProfile.qso) {
        updateData['qso'] = _qsoController.text;
      }
      if (_antiguidadeController.text != widget.userProfile.antiguidade) {
        updateData['antiguidade'] = _antiguidadeController.text;
      }

      if (updateData.isNotEmpty) {
        final success = await dashboardProvider.updateProfile(updateData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados atualizados com sucesso!')),
          );
          Navigator.of(context).pop();
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: const Text('Meus Dados'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dados não editáveis
                      _buildReadOnlyField('Nome', widget.userProfile.nome),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('ID Funcional', widget.userProfile.idFuncional ?? 'Não informado'),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Força', widget.userProfile.forcaSigla ?? 'Não informado'),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Posto/Graduação', widget.userProfile.postoGraduacaoNome ?? 'Não informado'),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Dados editáveis
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
                      const SizedBox(height: 32),
                      
                      // Intenções
                      const Text(
                        'Intenções de Permuta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (widget.intencoes.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma intenção cadastrada.'),
                          ),
                        )
                      else
                        ...widget.intencoes.map((intencao) => Card(
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
                          Navigator.of(context).pop();
                          // Abre o modal de gerenciar intenções
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar Alterações'),
                  ),
                ],
              ),
            ),
          ],
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

