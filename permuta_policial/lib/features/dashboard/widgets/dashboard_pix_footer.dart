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
          color: const Color(0xFF1C1F28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2D36), width: 0.5),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Apoio ao projeto',
              child: const Icon(Icons.favorite_outline, color: Color(0xFF66BB6A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPixKey ? _mensagem : 'Configure a chave PIX no painel',
                    style: const TextStyle(
                      color: Color(0x8FFFFFFF),
                      fontSize: 10,
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
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _chavePix!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chave PIX copiada! Obrigado pelo apoio.')),
                    );
                  },
                  child: const Text('Copiar', style: TextStyle(fontSize: 11)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x15FFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Em breve',
                  style: TextStyle(
                    color: Color(0x8FFFFFFF),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
