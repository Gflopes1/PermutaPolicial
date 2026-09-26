import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/repositories/admin_repository.dart';
import '../api/repositories/analytics_repository.dart';
import '../api/repositories/parceiros_repository.dart';
import '../api/repositories/consultoria_juridica_repository.dart';
import '../api/repositories/mapa_tatico_repository.dart';
import '../api/repositories/questions_repository.dart';
import '../services/analytics_service.dart';
import '../services/socket_service.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/mapa_tatico/providers/mapa_tatico_provider.dart';
import '../../features/mapa_tatico/widgets/mapa_tatico_bootstrap.dart';
import '../../features/questions/providers/questions_provider.dart';

/// Providers pesados criados só quando a rota correspondente é aberta.
class RouteScopedProviders {
  static Widget admin(BuildContext context, Widget child) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminProvider(
        ctx.read<AdminRepository>(),
        ctx.read<ParceirosRepository>(),
        ctx.read<ConsultoriaJuridicaRepository>(),
        ctx.read<AnalyticsRepository>(),
        ctx.read<AnalyticsService>(),
      ),
      child: child,
    );
  }

  static Widget mapaTatico(BuildContext context, Widget child) {
    return ChangeNotifierProvider(
      create: (ctx) => MapaTaticoProvider(
        ctx.read<MapaTaticoRepository>(),
        ctx.read<SocketService>(),
      ),
      child: MapaTaticoBootstrap(child: child),
    );
  }

  static Widget questions(BuildContext context, Widget child) {
    return ChangeNotifierProvider(
      create: (ctx) => QuestionsProvider(ctx.read<QuestionsRepository>()),
      child: child,
    );
  }
}
