// /lib/features/dashboard/screens/dashboard_entry_screen.dart

import 'package:flutter/material.dart';

import 'dashboard_screen_v3.dart';

/// Entrada do dashboard — carregamento direto (sem deferred) para evitar
/// falha de hash entre main.dart.js e *.part.js após deploy web.
class DashboardEntryScreen extends StatelessWidget {
  const DashboardEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => const DashboardScreenV3();
}
