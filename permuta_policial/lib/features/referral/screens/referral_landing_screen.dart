import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/repositories/referral_repository.dart';
import '../../../core/config/app_router.dart';
import '../../../core/services/referral_storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_status.dart';

class ReferralLandingScreen extends StatefulWidget {
  final String code;

  const ReferralLandingScreen({super.key, required this.code});

  @override
  State<ReferralLandingScreen> createState() => _ReferralLandingScreenState();
}

class _ReferralLandingScreenState extends State<ReferralLandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLanding());
  }

  Future<void> _handleLanding() async {
    final storage = context.read<ReferralStorageService>();
    final repo = context.read<ReferralRepository>();
    final auth = context.read<AuthProvider>();
    final code = widget.code.trim().toUpperCase();

    if (code.isEmpty) {
      context.go(AppRoutes.register);
      return;
    }

    // O ref vai SEMPRE na URL do cadastro: o backend revalida o código no signup (código
    // inexistente é ignorado sem erro). Antes, uma validação negativa/transitória descartava o
    // ref e o usuário caía em /auth/register sem ?ref=, perdendo a atribuição.
    final registerWithRef =
        '${AppRoutes.register}?ref=${Uri.encodeComponent(code)}';

    var valid = false;
    try {
      final validation = await repo.validateCode(code);
      valid = validation['valid'] == true;
      if (!valid) {
        debugPrint('[referral] código $code não validado pela API; mantendo ?ref= na URL');
      }
    } catch (e) {
      debugPrint('[referral] falha ao validar código $code: $e');
    }

    if (valid) {
      // Salva antes do clique: se registerClick falhar, o cadastro ainda recebe o código
      try {
        await storage.saveReferralCode(code);
      } catch (_) {}
      try {
        await repo.registerClick(code);
      } catch (_) {}
    }

    if (!mounted) return;

    if (auth.status == AuthStatus.authenticated) {
      if (valid) {
        try {
          await repo.attachReferral(code);
        } catch (_) {}
      }
      if (mounted) context.go(AppRoutes.dashboard);
    } else {
      context.go(registerWithRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
