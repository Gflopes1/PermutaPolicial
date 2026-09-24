import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/api/repositories/configuracoes_repository.dart';

class DashboardPixFooter extends StatefulWidget {
  const DashboardPixFooter({super.key});

  @override
  State<DashboardPixFooter> createState() => _DashboardPixFooterState();
}

class _DashboardPixFooterState extends State<DashboardPixFooter> {
  String? _chavePix;
  String _titulo = 'Apoie o projeto via PIX';
  String _mensagem = 'Ajude a manter a plataforma';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApoio());
  }

  Future<void> _loadApoio() async {
    try {
      final repo = context.read<ConfiguracoesRepository>();
      final data = await repo.getApoio();
      if (!mounted) return;
      setState(() {
        _chavePix = (data['chave_pix'] as String?)?.trim();
        _titulo = data['titulo'] as String? ?? _titulo;
        _mensagem = data['mensagem'] as String? ?? _mensagem;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPixKey = _chavePix != null && _chavePix!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2F1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E7D32), width: 0.5),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Apoio ao projeto',
              child: const Icon(Icons.favorite, color: Color(0xFF81C784), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF81C784),
                        ),
                  ),
                  Text(
                    hasPixKey ? _mensagem : 'Configure a chave PIX no painel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
            if (hasPixKey)
              Semantics(
                button: true,
                label: 'Copiar chave PIX',
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _chavePix!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chave PIX copiada! Obrigado pelo apoio.')),
                    );
                  },
                  child: const Text('Copiar'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Em breve',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
