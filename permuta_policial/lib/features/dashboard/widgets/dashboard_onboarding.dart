import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kGuideSeenKey = 'dashboard_guide_seen_v1';

/// Guia rápido exibido na primeira visita ao dashboard (qualquer tipo de login).
class DashboardOnboarding {
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kGuideSeenKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGuideSeenKey, true);
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!await shouldShow()) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Como usar o site')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _GuideStep(
                icon: Icons.person_outline,
                title: '1. Perfil e intenções',
                body:
                    'Em Meus Dados, confirme sua lotação e cadastre para onde deseja permutar.',
              ),
              SizedBox(height: 12),
              _GuideStep(
                icon: Icons.swap_horiz,
                title: '2. Ambiente de Permutas',
                body: 'Veja matches diretos, por proximidade e triangulares com outros agentes.',
              ),
              SizedBox(height: 12),
              _GuideStep(
                icon: Icons.apps_outlined,
                title: '3. Explore a plataforma',
                body:
                    'Mapa, Marketplace, Chat, Editais, Gestor de Horas e outras ferramentas estão nesta tela.',
              ),
              SizedBox(height: 12),
              _GuideStep(
                icon: Icons.swap_vert,
                title: '4. Novidades',
                body:
                    'Ao continuar, a página desce e sobe rapidamente para mostrar o restante do conteúdo.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi, continuar'),
          ),
        ],
      ),
    );

    await markSeen();
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
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
