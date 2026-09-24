import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kManualSeenKey = 'calendar_manual_seen_v1';

/// Manual do Gestor de Horas — exibido na primeira visita e pelo botão de ajuda.
class CalendarManual {
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
            Icon(Icons.schedule),
            SizedBox(width: 10),
            Expanded(child: Text('Como usar o Gestor de Horas')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ManualStep(
                icon: Icons.touch_app,
                title: '1. Marcar um dia',
                body:
                    'Toque em um dia do calendário para abrir os detalhes. '
                    'Escolha um tipo de dia (preset) na lista rápida ou toque em "Ver todos".',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.palette_outlined,
                title: '2. Tipos de dia (presets)',
                body:
                    'Presets são modelos como 6h, 8h, Folga ou Férias. '
                    'Gerencie, crie ou exclua tipos pelo botão "Tipos" na barra inferior.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.checklist,
                title: '3. Vários dias de uma vez',
                body:
                    'Toque em "Selecionar" na barra inferior, marque os dias desejados '
                    'e depois em "Aplicar tipo" para usar o mesmo preset em todos.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.payments_outlined,
                title: '4. Resumo e soldo',
                body:
                    'O painel lateral (ou botão "Resumo") mostra horas, etapas e estimativa '
                    'de soldo do mês com base nos dias marcados.',
              ),
              SizedBox(height: 12),
              _ManualStep(
                icon: Icons.settings,
                title: '5. Configurações',
                body:
                    'Ajuste salário base, hora extra, VA, etapas e previdência pelo ícone '
                    'de engrenagem. Os valores influenciam o cálculo automático.',
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
