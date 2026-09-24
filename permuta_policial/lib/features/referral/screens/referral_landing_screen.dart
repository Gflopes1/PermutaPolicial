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

    final registerWithRef =
        '${AppRoutes.register}?ref=${Uri.encodeComponent(code)}';

    try {
      final validation = await repo.validateCode(code);
      if (validation['valid'] != true) {
        if (mounted) context.go(AppRoutes.register);
        return;
      }

      // Salva antes do clique: se registerClick falhar, o cadastro ainda recebe o código
      await storage.saveReferralCode(code);
      try {
        await repo.registerClick(code);
      } catch (_) {}

      if (!mounted) return;

      if (auth.status == AuthStatus.authenticated) {
        try {
          await repo.attachReferral(code);
        } catch (_) {}
        if (mounted) context.go(AppRoutes.dashboard);
      } else {
        context.go(registerWithRef);
      }
    } catch (_) {
      if (mounted) context.go(registerWithRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
