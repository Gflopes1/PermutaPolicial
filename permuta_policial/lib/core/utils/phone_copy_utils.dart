import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_styles.dart';
import '../services/analytics_service.dart';

/// Copia telefone/QSO e registra evento de analytics.
Future<void> copiarTelefoneComAnalytics(
  BuildContext context, {
  required String telefone,
  required String origem,
  int? policialId,
}) async {
  final trimmed = telefone.trim();
  if (trimmed.isEmpty) return;

  await Clipboard.setData(ClipboardData(text: trimmed));

  try {
    await Provider.of<AnalyticsService>(context, listen: false).trackEvent(
      'copiar_telefone',
      metadata: {
        'origem': origem,
        if (policialId != null) 'policial_id': policialId,
      },
    );
  } catch (_) {}

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppStyles.successSnackBar('Número copiado!'),
    );
  }
}
