import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_bar_helper.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../widgets/sections/assinatura_section.dart';
import '../widgets/sections/forca_posto_section.dart';
import '../widgets/sections/identificacao_section.dart';
import '../widgets/sections/intencoes_section.dart';
import '../widgets/sections/lotacao_atual_section.dart';
import '../widgets/sections/preferencias_section.dart';
import '../widgets/sections/profile_header_widget.dart';
import '../../verificacao/widgets/verificacao_status_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final user = provider.userData;

        if (provider.isLoadingInitialData && user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meu Perfil')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meu Perfil')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Erro ao carregar perfil.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchInitialData(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meu Perfil'),
            actions: [
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchInitialData(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ProfileHeaderWidget(
                  userProfile: user,
                  intencoesCount: provider.intencoes.length,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VerificacaoStatusCard(userProfile: user),
                ),
                const SizedBox(height: 8),
                IdentificacaoSection(userProfile: user),
                const SizedBox(height: 8),
                ForcaPostoSection(userProfile: user),
                const SizedBox(height: 8),
                LotacaoAtualSection(userProfile: user),
                const SizedBox(height: 8),
                IntencoesSection(
                  intencoes: provider.intencoes,
                  userProfile: user,
                ),
                const SizedBox(height: 8),
                PreferenciasSection(userProfile: user),
                const SizedBox(height: 8),
                AssinaturaSection(userProfile: user),
              ],
            ),
          ),
        );
      },
    );
  }
}
