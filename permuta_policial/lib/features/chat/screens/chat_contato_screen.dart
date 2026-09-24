import 'package:flutter/material.dart';
import '../../../core/api/repositories/chat_repository.dart';

class ChatContatoScreen extends StatelessWidget {
  final Map<String, dynamic> perfil;

  const ChatContatoScreen({super.key, required this.perfil});

  static Future<void> open(BuildContext context, ChatRepository repo, int conversaId) async {
    try {
      final perfil = await repo.getPerfilContato(conversaId);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatContatoScreen(perfil: perfil),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotacao = _formatLotacao();

    return Scaffold(
      appBar: AppBar(title: const Text('Dados do contato')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(
              (perfil['nome'] as String? ?? '?')[0].toUpperCase(),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          _tile(Icons.person, 'Nome', perfil['nome']),
          _tile(Icons.shield, 'Força', perfil['forca_sigla'] ?? perfil['forca_nome']),
          _tile(Icons.military_tech, 'Posto/Graduação/Cargo', perfil['posto_graduacao_nome']),
          _tile(Icons.location_on, 'Lotação', lotacao),
        ],
      ),
    );
  }

  String _formatLotacao() {
    final mun = perfil['municipio_atual_nome'];
    final uf = perfil['estado_atual_sigla'];
    final unidade = perfil['unidade_atual_nome'];
    final partes = <String>[];
    if (mun != null) {
      partes.add(uf != null ? '$mun-$uf' : mun.toString());
    } else if (uf != null) {
      partes.add(uf.toString());
    }
    if (unidade != null) partes.add(unidade.toString());
    return partes.isEmpty ? 'Não informada' : partes.join(' · ');
  }

  Widget _tile(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
