// /lib/features/marketplace/screens/marketplace_create_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/marketplace_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/models/marketplace_item.dart';

class MarketplaceCreateFormScreen extends StatefulWidget {
  final List<XFile>? photos;
  final MarketplaceItem? itemToEdit;

  const MarketplaceCreateFormScreen({
    super.key,
    this.photos,
    this.itemToEdit,
  }) : assert(photos != null || itemToEdit != null, 
         'Deve fornecer photos para criação ou itemToEdit para edição');

  @override
  State<MarketplaceCreateFormScreen> createState() => 
      _MarketplaceCreateFormScreenState();
}

class _MarketplaceCreateFormScreenState 
    extends State<MarketplaceCreateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  
  String? _tipoSelecionado;
  bool _isSaving = false;
  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _tituloController = TextEditingController(text: item?.titulo ?? '');
    _descricaoController = TextEditingController(text: item?.descricao ?? '');
    _valorController = TextEditingController(
      text: item != null 
        ? item.valor.toStringAsFixed(2).replaceAll('.', ',')
        : '',
    );
    _tipoSelecionado = item?.tipo;
  }

  final Map<String, Map<String, dynamic>> _tipos = {
    'armas': {
      'label': 'Armas e Acessórios',
      'icon': Icons.gpp_maybe,
      'exemplo': 'Ex: Pistola Taurus .40, Coldre, Carregador',
    },
    'veiculos': {
      'label': 'Veículos',
      'icon': Icons.directions_car,
      'exemplo': 'Ex: Moto Honda CG 160, Carro Civic 2018',
    },
    'equipamentos': {
      'label': 'Equipamentos e Uniformes',
      'icon': Icons.work_outline,
      'exemplo': 'Ex: Colete balístico, Farda, Bota',
    },
  };

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _publicarAnuncio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoSelecionado == null) {
      _showMessage('Selecione o tipo do item', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    
    if (!_isEditing) {
      final user = Provider.of<DashboardProvider>(context, listen: false).userData;

      if (user == null) {
        _showMessage('Erro ao obter dados do usuário', isError: true);
        setState(() => _isSaving = false);
        return;
      }
    }

    final valor = double.tryParse(
      _valorController.text.replaceAll(',', '.').replaceAll('R\$', '').trim(),
    );

    if (valor == null || valor <= 0) {
      _showMessage('Digite um valor válido', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    bool success;
    if (_isEditing) {
      // Edição
      success = await provider.updateItem(
        id: widget.itemToEdit!.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        valor: valor,
        tipo: _tipoSelecionado!,
        fotos: [],
        fotosXFile: widget.photos?.isNotEmpty == true ? widget.photos : null,
      );
    } else {
      // Criação
      success = await provider.createItem(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        valor: valor,
        tipo: _tipoSelecionado!,
        fotos: [],
        fotosXFile: widget.photos,
      );
    }

    if (!mounted) return;

    if (success) {
      if (_isEditing) {
        Navigator.of(context).pop(true);
        _showMessage('Anúncio atualizado com sucesso!', isError: false);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('Anúncio criado! Aguardando aprovação.', isError: false);
      }
    } else {
      _showMessage(
        provider.errorMessage ?? (_isEditing ? 'Erro ao atualizar anúncio' : 'Erro ao criar anúncio'),
        isError: true,
      );
    }

    setState(() => _isSaving = false);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Anúncio' : 'Detalhes do Anúncio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview das fotos (apenas se houver fotos novas ou se for criação)
            if (widget.photos != null && widget.photos!.isNotEmpty)
              _buildPhotoPreview(theme),
            if (widget.photos != null && widget.photos!.isNotEmpty)
              const SizedBox(height: 24),
            
            // Tipo do item
            _buildTipoSection(theme),
            
            const SizedBox(height: 24),
            
            // Título
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título do anúncio *',
                hintText: 'Ex: Pistola Taurus .40 Semi-nova',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '${_tituloController.text.length}/100',
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Título é obrigatório';
                }
                if (value.trim().length < 5) {
                  return 'Título muito curto (mínimo 5 caracteres)';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            
            const SizedBox(height: 20),
            
            // Valor
            TextFormField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: 'Valor *',
                hintText: '0,00',
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Valor é obrigatório';
                }
                final valorNum = double.tryParse(
                  value.replaceAll(',', '.').replaceAll('R\$', '').trim(),
                );
                if (valorNum == null || valorNum <= 0) {
                  return 'Digite um valor válido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Descrição (opcional)
            TextFormField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Descreva o estado, detalhes, acessórios inclusos...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '${_descricaoController.text.length}/500',
                alignLabelWithHint: true,
              ),
              maxLength: 500,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            
            const SizedBox(height: 24),
            
            // Aviso importante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Informações Importantes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    '• Anúncios passam por moderação antes de serem publicados',
                  ),
                  _buildInfoItem(
                    '• Anúncios são excluídos automaticamente após 1 mês',
                  ),
                  _buildInfoItem(
                    '• O site apenas conecta compradores e vendedores',
                  ),
                  _buildInfoItem(
                    '• Negociação e transação são por sua conta e risco',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botão publicar/atualizar
            ElevatedButton(
              onPressed: _isSaving ? null : _publicarAnuncio,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isEditing ? Icons.save : Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'Salvar Alterações' : 'Publicar Anúncio',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildPhotoPreview(ThemeData theme) {
    final photos = widget.photos ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Novas Fotos (opcional)' : 'Fotos do Anúncio',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'As fotos atuais serão mantidas se nenhuma nova for adicionada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.file(
                        File(photos[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      if (index == 0)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  Widget _buildTipoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo do Item *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._tipos.entries.map((entry) {
          final key = entry.key;
          final data = entry.value;
          final isSelected = _tipoSelecionado == key;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _tipoSelecionado = key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor.withAlpha(20)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        data['icon'] as IconData,
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['exemplo'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue.shade900,
          height: 1.4,
        ),
      ),
    );
  }
}