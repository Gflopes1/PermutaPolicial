import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/mapa_tatico_provider.dart';

/// Inicializa o [MapaTaticoProvider] uma vez para todas as rotas do mapa tático.
class MapaTaticoBootstrap extends StatefulWidget {
  final Widget child;

  const MapaTaticoBootstrap({super.key, required this.child});

  @override
  State<MapaTaticoBootstrap> createState() => _MapaTaticoBootstrapState();
}

class _MapaTaticoBootstrapState extends State<MapaTaticoBootstrap> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final provider = context.read<MapaTaticoProvider>();
    final auth = context.read<AuthProvider>();
    provider.setCurrentUserId(auth.user?.id);
    await provider.loadPreferences();
    await Future.wait([
      provider.initializeRealtime(),
      provider.loadGroups(),
    ]);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
