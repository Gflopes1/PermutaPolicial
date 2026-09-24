import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_router.dart';
import '../../../core/models/consultoria_advogado.dart';
import '../widgets/consultoria_advogado_card.dart';

class ConsultoriaAdvogadosListScreen extends StatelessWidget {
  final List<ConsultoriaAdvogado> advogados;

  const ConsultoriaAdvogadosListScreen({
    super.key,
    required this.advogados,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultoria Jurídica'),
      ),
      body: advogados.isEmpty
          ? const Center(child: Text('Nenhum advogado ou escritório disponível.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: advogados.length,
              itemBuilder: (context, index) {
                final adv = advogados[index];
                return ConsultoriaAdvogadoCard(
                  advogado: adv,
                  onTap: () => context.push('${AppRoutes.consultoriaJuridica}/${adv.id}'),
                );
              },
            ),
    );
  }
}
