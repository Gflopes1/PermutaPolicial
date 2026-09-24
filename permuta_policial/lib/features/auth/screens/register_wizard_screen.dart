import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/api/repositories/dados_repository.dart';
import 'package:permuta_policial/core/services/referral_storage_service.dart';
import 'package:permuta_policial/core/config/app_router.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/core/config/app_theme.dart';
import 'package:permuta_policial/core/services/analytics_service.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/providers/auth_status.dart';
import 'package:permuta_policial/features/auth/utils/auth_validators.dart';
import 'package:permuta_policial/features/auth/utils/oauth_helpers.dart';
import 'package:permuta_policial/features/auth/widgets/auth_scaffold.dart';
import 'package:permuta_policial/features/auth/widgets/password_strength_meter.dart';
import 'package:permuta_policial/shared/widgets/custom_dropdown_search.dart';
import 'package:permuta_policial/shared/widgets/custom_text_field.dart';

class RegisterWizardScreen extends StatefulWidget {
  const RegisterWizardScreen({super.key});

  @override
  State<RegisterWizardScreen> createState() => _RegisterWizardScreenState();
}

class _RegisterWizardScreenState extends State<RegisterWizardScreen> {
  final _pageController = PageController();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _idController = TextEditingController();
  final _telefoneController = TextEditingController();

  dynamic _forcaSelecionada;
  bool _consentimentoLGPD = false;
  int _currentStep = 0;
  String? _stepError;
  String? _referralCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReferralCode());
  }

  Future<void> _loadReferralCode() async {
    final storage = Provider.of<ReferralStorageService>(context, listen: false);
    final uri = GoRouterState.of(context).uri;
    final fromQuery = storage.parseRefFromUri(uri);
    if (fromQuery != null) {
      await storage.saveReferralCode(fromQuery);
    }
    final code = fromQuery ?? await storage.getReferralCode();
    if (mounted) {
      setState(() => _referralCode = code);
    }
  }

  Future<String?> _resolveReferralCode() async {
    if (_referralCode != null && _referralCode!.isNotEmpty) {
      return _referralCode;
    }
    final storage = Provider.of<ReferralStorageService>(context, listen: false);
    final uri = GoRouterState.of(context).uri;
    return storage.parseRefFromUri(uri) ?? await storage.getReferralCode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _idController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    setState(() => _stepError = null);
    switch (_currentStep) {
      case 0:
        return _formKeyStep1.currentState?.validate() ?? false;
      case 1:
        return _formKeyStep2.currentState?.validate() ?? false;
      case 2:
        if (_forcaSelecionada == null) {
          setState(() => _stepError = 'Selecione sua força policial.');
          return false;
        }
        if (!_consentimentoLGPD) {
          setState(() => _stepError = 'Você precisa aceitar os Termos de Uso.');
          return false;
        }
        return _formKeyStep3.currentState?.validate() ?? true;
      default:
        return false;
    }
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _doRegister();
    }
  }

  void _back() {
    if (_currentStep == 0) {
      context.pop();
      return;
    }
    setState(() {
      _currentStep--;
      _stepError = null;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _doRegister() async {
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent('register_attempt', metadata: {
        'forca_id': _forcaSelecionada.id,
      });
    } catch (_) {}

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final referralCode = await _resolveReferralCode();
    if (referralCode != null && referralCode.isNotEmpty) {
      await Provider.of<ReferralStorageService>(context, listen: false)
          .saveReferralCode(referralCode);
    }
    final userData = {
      'nome': _nomeController.text.trim(),
      'id_funcional': _idController.text.trim(),
      'forca_id': _forcaSelecionada.id,
      'email': _emailController.text.trim(),
      'qso': _telefoneController.text.trim(),
      'senha': _senhaController.text,
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
    };

    final response = await auth.register(userData);
    if (!mounted) return;

    if (response != null) {
      final msg = response['message'] as String? ?? 'Conta criada com sucesso!';
      OAuthHelpers.showMessage(context, msg, isSuccess: true);
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        await analytics.trackEvent('register_success');
      } catch (_) {}

      final requiresConfirmation =
          response['requires_email_confirmation'] as bool? ?? true;
      if (requiresConfirmation) {
        final confirmPath =
            '${AppRoutes.confirmEmail}?email=${Uri.encodeComponent(_emailController.text.trim())}';
        final refForConfirm = referralCode;
        context.go(
          refForConfirm != null && refForConfirm.isNotEmpty
              ? '$confirmPath&ref=${Uri.encodeComponent(refForConfirm)}'
              : confirmPath,
        );
      } else {
        context.go(AppRoutes.auth);
      }
    } else {
      final err = auth.errorMessage ?? 'Erro ao criar conta. Tente novamente.';
      setState(() => _stepError = err);
      OAuthHelpers.showMessage(context, err);
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        await analytics.trackEvent('register_failed');
      } catch (_) {}
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
              Row(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _back,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Voltar',
                  ),
                  Expanded(
                    child: Text(
                      'Criar conta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              _StepIndicator(current: _currentStep, total: 3),
              if (_referralCode != null && _referralCode!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4A90D9).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Indicação ativa: ${_referralCode!}. Confirme o e-mail após o cadastro para contabilizar.',
                    style: const TextStyle(color: Color(0xFFB8D4F0), fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: _currentStep == 0 ? 520 : 420,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
              if (_stepError != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _stepError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.primaryButton,
                  onPressed: isLoading ? null : _next,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(_currentStep == 2 ? 'Criar Conta' : 'Continuar'),
                ),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final ref = await _resolveReferralCode();
                        if (!mounted) return;
                        final dest = ref != null && ref.isNotEmpty
                            ? '${AppRoutes.auth}?ref=${Uri.encodeComponent(ref)}'
                            : AppRoutes.auth;
                        context.go(dest);
                      },
                child: const Text('Já tenho uma conta'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: AutofillGroup(
        child: ListView(
          children: [
            Text(
              'Cadastro rápido',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Image.asset('assets/images/google_logo.png', height: 22, width: 22),
                label: const Text('Cadastrar com Google'),
                style: AppStyles.outlinedButton,
                onPressed: () async {
                  final ref = await _resolveReferralCode();
                  if (!mounted) return;
                  await OAuthHelpers.loginWithGoogle(context, referralCode: ref);
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Image.asset('assets/images/microsoft_logo.png', height: 20, width: 20),
                label: const Text('Cadastrar com e-mail institucional'),
                style: AppStyles.outlinedButton,
                onPressed: () async {
                  final ref = await _resolveReferralCode();
                  if (!mounted) return;
                  await OAuthHelpers.loginWithMicrosoft(context, referralCode: ref);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'ou com email e senha',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Email e senha',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _senhaController,
              label: 'Senha',
              prefixIcon: Icons.lock,
              obscureText: true,
              showPasswordToggle: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.password,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _senhaController,
              builder: (_, value, __) => PasswordStrengthMeter(password: value.text),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmarSenhaController,
              label: 'Confirmar Senha',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              showPasswordToggle: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _next(),
              validator: (v) =>
                  AuthValidators.confirmPassword(v, _senhaController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: ListView(
        children: [
          Text(
            'Seus dados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nomeController,
            label: 'Nome Completo',
            prefixIcon: Icons.person,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => AuthValidators.required(v, 'Nome'),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _idController,
            label: 'ID Funcional',
            prefixIcon: Icons.badge,
            textInputAction: TextInputAction.next,
            validator: (v) => AuthValidators.required(v, 'ID Funcional'),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _telefoneController,
            label: 'Telefone',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            onFieldSubmitted: (_) => _next(),
            validator: (v) => AuthValidators.required(v, 'Telefone'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    return Form(
      key: _formKeyStep3,
      child: ListView(
        children: [
          Text(
            'Força e termos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          CustomDropdownSearch<dynamic>(
            label: 'Força Policial',
            asyncItems: (_) => dadosRepo.getForcas(),
            itemAsString: (item) => '${item.sigla} - ${item.nome}',
            onChanged: (value) => setState(() => _forcaSelecionada = value),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text(
              'Li e aceito os Termos de Uso.',
              style: TextStyle(fontSize: 14),
            ),
            value: _consentimentoLGPD,
            onChanged: (v) => setState(() => _consentimentoLGPD = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          TextButton(
            onPressed: () => OAuthHelpers.launchExternal(
              context,
              'https://br.permutapolicial.com.br/termos.html',
            ),
            child: const Text('Ler Termos de Uso'),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryLight : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
