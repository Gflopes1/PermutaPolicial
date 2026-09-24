import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/config/app_router.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/providers/auth_status.dart';
import 'package:permuta_policial/features/auth/utils/auth_validators.dart';
import 'package:permuta_policial/features/auth/utils/oauth_helpers.dart';
import 'package:permuta_policial/core/services/referral_storage_service.dart';
import 'package:permuta_policial/features/auth/widgets/auth_scaffold.dart';
import 'package:permuta_policial/features/auth/widgets/otp_code_input.dart';

class ConfirmEmailScreen extends StatefulWidget {
  final String? email;

  const ConfirmEmailScreen({super.key, this.email});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  String _code = '';
  String? _inlineError;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  String get _email {
    if (widget.email != null && widget.email!.isNotEmpty) return widget.email!;
    return GoRouterState.of(context).uri.queryParameters['email'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _confirm() async {
    setState(() => _inlineError = null);
    final err = AuthValidators.otpCode(_code);
    if (err != null) {
      setState(() => _inlineError = err);
      return;
    }
    if (_email.isEmpty) {
      setState(() => _inlineError = 'Email não informado. Volte e tente novamente.');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final storage = Provider.of<ReferralStorageService>(context, listen: false);
    final referralCode =
        storage.parseRefFromUri(GoRouterState.of(context).uri) ??
            await storage.getReferralCode();
    final success = await auth.confirmEmail(
      _email,
      _code,
      referralCode: referralCode,
    );
    if (!mounted) return;

    if (success) {
      await storage.clearReferralCode();
      OAuthHelpers.showMessage(
        context,
        'Email confirmado com sucesso! Você já pode fazer login.',
        isSuccess: true,
      );
      context.go(AppRoutes.auth);
    } else {
      setState(() => _inlineError = auth.errorMessage ?? 'Código inválido.');
    }
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0 || _email.isEmpty) return;

    // Reutiliza o endpoint de recuperação: gera novo código na mesma tabela.
    // O usuário usa o código no fluxo de confirmação de email.
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.requestPasswordReset(_email);
    if (!mounted) return;

    if (ok) {
      OAuthHelpers.showMessage(
        context,
        'Se o email estiver cadastrado, um novo código foi enviado. Verifique também o spam.',
        isSuccess: true,
      );
      _startCooldown();
    } else {
      OAuthHelpers.showMessage(
        context,
        auth.errorMessage ?? 'Não foi possível reenviar o código.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.status == AuthStatus.authenticating;
        return AuthScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Verificar Email', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                _email.isEmpty
                    ? 'Enviamos um código de 6 dígitos para o seu email.'
                    : 'Enviamos um código de 6 dígitos para $_email.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.mail_outline, size: 20, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Não encontrou? Verifique spam/lixo eletrônico antes de solicitar um novo código.',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OtpCodeInput(
                onChanged: (code) => setState(() {
                  _code = code;
                  _inlineError = null;
                }),
                onCompleted: (_) => _confirm(),
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _inlineError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.primaryButton,
                  onPressed: isLoading ? null : _confirm,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Confirmar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => OAuthHelpers.openEmailApp(context, to: _email),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Abrir meu email'),
                  style: AppStyles.outlinedButton,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: (_cooldownSeconds > 0 || isLoading) ? null : _resend,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Reenviar código (${_cooldownSeconds}s)'
                      : 'Reenviar código',
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.go(AppRoutes.auth),
                child: const Text('Voltar ao Login'),
              ),
            ],
          ),
        );
      },
    );
  }
}
