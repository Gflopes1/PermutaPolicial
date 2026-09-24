// Mantido apenas por compatibilidade. Toda navegação deve usar PermutasUnificadasScreen.

import 'package:flutter/material.dart';

import 'permutas_unificadas_screen.dart';

@Deprecated('Use PermutasUnificadasScreen via AppRoutes.permutas')
class PermutasInteligentesScreen extends StatelessWidget {
  const PermutasInteligentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PermutasUnificadasScreen();
  }
}
