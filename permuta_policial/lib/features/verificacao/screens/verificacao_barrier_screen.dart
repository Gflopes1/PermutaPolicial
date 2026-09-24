import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_router.dart';
import '../../../core/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../widgets/verificacao_metodo_buttons.dart';
import '../widgets/verificacao_whatsapp_helper.dart';

class VerificacaoBarrierScreen extends StatefulWidget {
  final String titulo;
  final String descricao;
  final String? contextoWhatsapp;
  final VoidCallback? onVerified;

  const VerificacaoBarrierScreen({
    super.key,
    required this.titulo,
    required this.descricao,
    this.contextoWhatsapp,
    this.onVerified,
  });

  @override
  State<VerificacaoBarrierScreen> createState() => _VerificacaoBarrierScreenState();
}

class _VerificacaoBarrierScreenState extends State<VerificacaoBarrierScreen> {
  bool _openingWhatsapp = false;

  Future<void> _openWhatsapp(UserProfile? user) async {
    setState(() => _openingWhatsapp = true);
    try {
      final nome = (user?.nome.trim().isNotEmpty == true) ? user!.nome.trim() : 'agente';
      final idFuncional = (user?.idFuncional?.trim().isNotEmpty == true)
          ? user!.idFuncional!.trim()
          : 'não informado';
      final ok = await VerificacaoWhatsappHelper.openVerificationRequest(
        nome: nome,
        idFuncional: idFuncional,
        contexto: widget.contextoWhatsapp,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingWhatsapp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificação necessária')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.verified_user_outlined, size: 72, color: Color(0xFF856404)),
          const SizedBox(height: 20),
          Text(
            widget.titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.descricao,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 28),
          VerificacaoWhatsappButton(
            loading: _openingWhatsapp,
            onPressed: () => _openWhatsapp(user),
          ),
          const SizedBox(height: 12),
          VerificacaoDocumentoButton(
            label: 'Verificar conta com funcional ou contracheque',
            onPressed: () async {
              final verified = await context.push<bool>(AppRoutes.verificacaoDocumento);
              if (!mounted) return;
              if (verified == true) {
                await context.read<AuthProvider>().refreshProfile();
                if (context.mounted) {
                  await context.read<DashboardProvider>().fetchInitialData();
                }
                widget.onVerified?.call();
                if (context.mounted && Navigator.canPop(context)) {
                  context.pop(true);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

bool userNeedsAgentVerification(UserProfile? user) {
  if (user == null) return true;
  return !user.agenteVerificado;
}
