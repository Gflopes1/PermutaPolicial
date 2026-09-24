import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kManualSeenKey = 'mapa_tatico_manual_seen_v1';

/// Manual do Mapa Tático — exibido na primeira visita e disponível pelo botão de ajuda.
class MapaTaticoManual {
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kManualSeenKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kManualSeenKey, true);
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!await shouldShow()) return;
    if (!context.mounted) return;
    await show(context, markAsSeen: true);
  }

  static Future<void> show(BuildContext context, {bool markAsSeen = false}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.map_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Como usar o Mapa Tático')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ManualStep(
                icon: Icons.map,
                title: '1. Mapa',
                body:
                    'Visualize marcadores operacionais, logísticos e do mapa nacional. '
                    'Use as abas Operacional, Logística e Nacional quando estiver em um grupo.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.touch_app,
                title: '2. Criar marcadores',
                body:
                    'Pressione e segure no mapa para adicionar um ponto. '
                    'Toque em um marcador para ver detalhes, comentários e rotas.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.list,
                title: '3. Lista',
                body: 'Veja todos os marcadores da aba atual em formato de lista, com distância e validade.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.group,
                title: '4. Grupos',
                body:
                    'Crie ou entre em grupos fechados para mapas operacional e logístico da equipe. '
                    'Convide colegas, gerencie membros e alterne o grupo ativo em "Seus grupos".',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.my_location,
                title: '5. GPS e alertas',
                body:
                    'Ative a localização para centralizar o mapa, compartilhar posição com o grupo '
                    'e receber alertas de proximidade em pontos operacionais.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );

    if (markAsSeen) {
      await markSeen();
    }
  }
}

class _ManualStep extends StatelessWidget {
  const _ManualStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
