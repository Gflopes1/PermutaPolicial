import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/config/app_router.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/utils/auth_validators.dart';
import 'package:permuta_policial/features/auth/utils/oauth_helpers.dart';
import 'package:permuta_policial/features/auth/widgets/auth_scaffold.dart';
import 'package:permuta_policial/features/auth/widgets/otp_code_input.dart';
import 'package:permuta_policial/features/auth/widgets/password_strength_meter.dart';
import 'package:permuta_policial/shared/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  int _step = 1;
  String _code = '';
  String? _inlineError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _novaSenhaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() => _inlineError = null);
    if (!(_formKeyStep1.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      OAuthHelpers.showMessage(
        context,
        'Se o email estiver cadastrado, um código foi enviado.',
        isSuccess: true,
      );
      setState(() => _step = 2);
    } else {
      setState(() => _inlineError = auth.errorMessage ?? 'Erro ao solicitar código.');
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _inlineError = null);
    if (!(_formKeyStep2.currentState?.validate() ?? false)) return;
    final codeErr = AuthValidators.otpCode(_code);
    if (codeErr != null) {
      setState(() => _inlineError = codeErr);
      return;
    }

    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tempToken = await auth.validateResetCode(
      _emailController.text.trim(),
      _code,
    );

    if (!mounted) return;

    if (tempToken == null) {
      setState(() {
        _loading = false;
        _inlineError = auth.errorMessage ?? 'Código inválido.';
      });
      return;
    }

    final ok = await auth.resetPassword(tempToken, _novaSenhaController.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      OAuthHelpers.showMessage(context, 'Senha redefinida com sucesso!', isSuccess: true);
      context.go(AppRoutes.auth);
    } else {
      setState(() => _inlineError = auth.errorMessage ?? 'Erro ao redefinir senha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: _step == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Recuperar Senha', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text(
            'Informe seu e-mail para receber o código de recuperação.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _requestCode(),
            validator: AuthValidators.email,
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 8),
            Text(_inlineError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: AppStyles.primaryButton,
              onPressed: _loading ? null : _requestCode,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Enviar Código'),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => context.go(AppRoutes.auth),
            child: const Text('Voltar ao Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Redefinir Senha', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Código enviado para ${_emailController.text.trim()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            OtpCodeInput(
              onChanged: (c) => setState(() {
                _code = c;
                _inlineError = null;
              }),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _novaSenhaController,
              label: 'Nova Senha',
              prefixIcon: Icons.lock,
              obscureText: true,
              showPasswordToggle: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.password,
            ),
            PasswordStrengthMeter(password: _novaSenhaController.text),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmarSenhaController,
              label: 'Confirmar Nova Senha',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              showPasswordToggle: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _resetPassword(),
              validator: (v) =>
                  AuthValidators.confirmPassword(v, _novaSenhaController.text),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 8),
              Text(_inlineError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppStyles.primaryButton,
                onPressed: _loading ? null : _resetPassword,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Redefinir Senha'),
              ),
            ),
            TextButton(
              onPressed: _loading ? null : () => context.go(AppRoutes.auth),
              child: const Text('Voltar ao Login'),
            ),
          ],
        ),
      ),
    );
  }
}
