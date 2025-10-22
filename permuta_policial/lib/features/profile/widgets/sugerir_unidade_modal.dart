// /lib/features/profile/widgets/sugerir_unidade_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dados/providers/dados_provider.dart'; // Importa o novo provider

class SugerirUnidadeModal extends StatefulWidget {
  final int municipioId;
  final int forcaId;

  const SugerirUnidadeModal({
    super.key,
    required this.municipioId,
    required this.forcaId,
  });

  @override
  State<SugerirUnidadeModal> createState() => _SugerirUnidadeModalState();
}

class _SugerirUnidadeModalState extends State<SugerirUnidadeModal> {
  final _textController = TextEditingController();
  bool _isSaving = false; // Estado de loading local para o botão

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _enviarSugestao() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite o nome da unidade.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Usa o DadosProvider para executar a ação
    final provider = Provider.of<DadosProvider>(context, listen: false);
    final successMessage = await provider.sugerirUnidade(
      nomeSugerido: _textController.text.trim(),
      municipioId: widget.municipioId,
      forcaId: widget.forcaId,
    );

    if (!mounted) return;

    if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Fecha o modal em caso de sucesso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Ocorreu um erro.'), backgroundColor: Colors.red),
      );
    }
    
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sugerir Nova Unidade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Se a unidade que você procura não está na lista, digite o nome completo dela abaixo para que seja adicionada.'),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Nome da Unidade',
              // Estilo virá do AppTheme
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _enviarSugestao,
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar Sugestão'),
        ),
      ],
    );
  }
}