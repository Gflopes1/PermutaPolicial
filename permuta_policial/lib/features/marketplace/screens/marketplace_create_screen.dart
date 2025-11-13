// /lib/features/marketplace/screens/marketplace_create_screen.dart

import 'dart:typed_data'; // Necessário para Uint8List
import 'package:flutter/material.dart';
// kIsWeb ainda é útil, mas não para os arquivos
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/marketplace_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_client.dart';

class MarketplaceCreateScreen extends StatefulWidget {
  final MarketplaceItem? itemToEdit;

  const MarketplaceCreateScreen({super.key, this.itemToEdit});

  @override
  State<MarketplaceCreateScreen> createState() => _MarketplaceCreateScreenState();
}

class _MarketplaceCreateScreenState extends State<MarketplaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  String? _tipoSelecionado;
  
  // Usamos apenas XFile, que funciona em web e mobile.
  final List<XFile> _fotosXFile = []; 
  
  final List<String> _fotosExistentes = [];
  final ImagePicker _picker = ImagePicker();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.itemToEdit != null;
    if (_isEditMode && widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _tituloController.text = item.titulo;
      _descricaoController.text = item.descricao;
      _valorController.text = item.valor.toStringAsFixed(2);
      _tipoSelecionado = item.tipo;
      _fotosExistentes.addAll(item.fotos);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _adicionarFoto() async {
    // A lógica de contagem agora é unificada
    final totalFotos = _fotosXFile.length + _fotosExistentes.length;
    if (totalFotos >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 3 fotos permitidas')),
      );
      return;
    }

    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      
      if (foto != null) {
        setState(() {
          // Adiciona apenas à lista _fotosXFile
          _fotosXFile.add(foto);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar foto: $e')),
        );
      }
    }
  }

  void _removerFoto(int index) {
    setState(() {
      // Remove apenas da lista _fotosXFile
      _fotosXFile.removeAt(index);
    });
  }

  void _removerFotoExistente(int index) {
    setState(() => _fotosExistentes.removeAt(index));
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo do item')),
      );
      return;
    }
    // Lógica de contagem unificada
    final totalFotos = _fotosXFile.length + _fotosExistentes.length;
    if (totalFotos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma foto')),
      );
      return;
    }

    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    
    if (_isEditMode) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final user = dashboardProvider.userData;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao obter dados do usuário')),
        );
        return;
      }

      final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
      if (valor == null || valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor inválido')),
        );
        return;
      }

      final success = await provider.updateItem(
        id: widget.itemToEdit!.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        valor: valor,
        tipo: _tipoSelecionado!,
        fotos: null, // Não usamos mais List<File>
        fotosXFile: _fotosXFile.isNotEmpty ? _fotosXFile : null, // Envia apenas XFile
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item atualizado com sucesso! Aguardando aprovação.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Erro ao atualizar item')),
        );
      }
    } else {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final user = dashboardProvider.userData;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao obter dados do usuário')),
        );
        return;
      }

      final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
      if (valor == null || valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor inválido')),
        );
        return;
      }

      final success = await provider.createItem(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        valor: valor,
        tipo: _tipoSelecionado!,
        fotos: [], // Não usamos mais List<File>
        fotosXFile: _fotosXFile, // Envia apenas XFile
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item criado com sucesso! Aguardando aprovação.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Erro ao criar item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final baseUrl = apiClient.baseUrl;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Editar Anúncio' : 'Criar Anúncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Título é obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (v) => v?.isEmpty ?? true ? 'Descrição é obrigatória' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$) *',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Valor é obrigatório';
                final valor = double.tryParse(v!.replaceAll(',', '.'));
                if (valor == null || valor <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'armas', child: Text('Armas')),
                DropdownMenuItem(value: 'veiculos', child: Text('Veículos')),
                DropdownMenuItem(value: 'equipamentos', child: Text('Equipamentos')),
              ],
              onChanged: (value) => setState(() => _tipoSelecionado = value),
              validator: (v) => v == null ? 'Tipo é obrigatório' : null,
            ),
            const SizedBox(height: 24),
            const Text('Fotos (máximo 3) *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Fotos existentes (via URL)
                ..._fotosExistentes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fotoUrl = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$baseUrl$fotoUrl',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removerFotoExistente(index),
                        ),
                      ),
                    ],
                  );
                }),
                
                // Fotos novas (XFile, exibidas com FutureBuilder e Image.memory)
                ..._fotosXFile.asMap().entries.map((entry) {
                  final index = entry.key;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // Este FutureBuilder funciona em AMBAS as plataformas (web e mobile)
                        child: FutureBuilder<Uint8List>(
                          future: _fotosXFile[index].readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removerFoto(index),
                        ),
                      ),
                    ],
                  );
                }),
                
                // Botão de adicionar
                if (_fotosExistentes.length + _fotosXFile.length < 3)
                  InkWell(
                    onTap: _adicionarFoto,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate, size: 48),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Importante: Nós do site não participamos da venda, apenas conectamos os interessados. O anúncio será revisado antes de ser publicado.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Os anúncios são excluídos automaticamente após 1 mês da postagem.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer<MarketplaceProvider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(_isEditMode ? 'Salvar Alterações' : 'Criar Anúncio'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}