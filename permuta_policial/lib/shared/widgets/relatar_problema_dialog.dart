// /lib/shared/widgets/relatar_problema_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/analytics_service.dart';
import '../../core/api/api_client.dart';
import '../../core/config/app_styles.dart';
import '../../core/config/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class RelatarProblemaDialog extends StatefulWidget {
  final String nomePagina;

  const RelatarProblemaDialog({
    super.key,
    required this.nomePagina,
  });

  static Future<void> show(BuildContext context, String nomePagina) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return RelatarProblemaDialog(nomePagina: nomePagina);
      },
    );
  }

  @override
  State<RelatarProblemaDialog> createState() => _RelatarProblemaDialogState();
}

class _RelatarProblemaDialogState extends State<RelatarProblemaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _detalhesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detalhesController.dispose();
    super.dispose();
  }

  Future<void> _enviarRelatorio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Faça login para enviar um relato com sua identificação.'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      await apiClient.post('/api/problemas/relato', {
        'pagina': widget.nomePagina,
        'detalhes': _detalhesController.text.trim(),
      }, requireAuth: true);

      // Também registra via analytics para histórico
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackEvent(
        'problema_relatado',
        metadata: {
          'pagina': widget.nomePagina,
          'detalhes': _detalhesController.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      // Mostra mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Problema relatado com sucesso! Obrigado pelo feedback.'),
      );

      // Fecha o dialog
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Erro ao enviar relatório. Tente novamente.'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildIdentificacaoUsuario(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withAlpha(100)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'É necessário estar logado para que possamos identificar quem fez o relato.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final idFuncional = user.idFuncional?.trim();
    final forca = user.forcaSigla?.trim();
    final identificadores = [
      if (idFuncional != null && idFuncional.isNotEmpty) 'ID funcional: $idFuncional',
      if (forca != null && forca.isNotEmpty) 'Força: $forca',
      if (user.email != null && user.email!.isNotEmpty) user.email,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviando como',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 2),
                Text(
                  user.nome,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (identificadores.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    identificadores,
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.bug_report, color: AppTheme.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Relate seu problema',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome da página (somente leitura)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Página',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.nomePagina,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildIdentificacaoUsuario(context, auth),
              const SizedBox(height: 16),

              // Campo de detalhes
              TextFormField(
                controller: _detalhesController,
                decoration: InputDecoration(
                  labelText: 'Detalhes do problema',
                  hintText: 'Descreva o problema que você encontrou...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, descreva o problema';
                  }
                  if (value.trim().length < 10) {
                    return 'Por favor, forneça mais detalhes (mínimo 10 caracteres)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || auth.user == null) ? null : _enviarRelatorio,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
