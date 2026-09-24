// /lib/features/permutas/screens/permutas_screen.dart
//
// Mantido apenas por compatibilidade. Toda navegação deve usar PermutasUnificadasScreen.

import 'package:flutter/material.dart';

import 'permutas_unificadas_screen.dart';

@Deprecated('Use PermutasUnificadasScreen via AppRoutes.permutas')
class PermutasScreen extends StatelessWidget {
  final int initialTabIndex;

  const PermutasScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return PermutasUnificadasScreen(initialTabIndex: initialTabIndex);
  }
}
