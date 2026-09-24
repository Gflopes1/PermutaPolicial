import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/config/app_router.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/core/services/analytics_service.dart';
import 'package:permuta_policial/core/services/atualizacao_service.dart';
import 'package:permuta_policial/core/services/referral_storage_service.dart';
import 'package:permuta_policial/core/services/visitor_prefs.dart';
import 'package:permuta_policial/core/utils/profile_completion.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/providers/auth_status.dart';
import 'package:permuta_policial/features/auth/utils/auth_validators.dart';
import 'package:permuta_policial/features/auth/utils/oauth_helpers.dart';
import 'package:permuta_policial/features/auth/widgets/auth_scaffold.dart';
import 'package:permuta_policial/features/notificacoes/widgets/atualizacao_dialog.dart';
import 'package:permuta_policial/shared/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailExpanded = false;
  String? _inlineError;
  String? _referralCode;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.addListener(_onAuthStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      _verificarAtualizacao();
      _showQueryErrorIfAny();
      _loadReferralCode();
    });
  }

  Future<void> _loadReferralCode() async {
    final storage = Provider.of<ReferralStorageService>(context, listen: false);
    final uri = GoRouterState.of(context).uri;
    final code = storage.parseRefFromUri(uri) ?? await storage.getReferralCode();
    if (mounted && code != null) {
      setState(() => _referralCode = code);
    }
  }

  void _showQueryErrorIfAny() {
    final message = OAuthHelpers.resolveOAuthError(GoRouterState.of(context).uri);
    if (message != null) {
      OAuthHelpers.showMessage(context, message);
    }
  }

  Future<void> _verificarAtualizacao() async {
    try {
      final svc = Provider.of<AtualizacaoService>(context, listen: false);
      final nota = await svc.verificarNovaAtualizacao();
      if (nota != null && mounted) {
        final versao = await svc.obterVersaoAtual();
        if (versao != null && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AtualizacaoDialog(nota: nota, versao: versao),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar atualização: $e');
    }
  }

  Future<void> _trackPageView() async {
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackPageView('/auth');
      await analytics.trackEvent('auth_screen_viewed', metadata: {'state': 'login'});
    } catch (_) {}
  }

  @override
  void dispose() {
    Provider.of<AuthProvider>(context, listen: false).removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      final dest = isProfileIncomplete(auth.user)
          ? AppRoutes.completarPerfil
          : AppRoutes.dashboard;
      context.go(dest);
    }
    if (auth.status == AuthStatus.unauthenticated && auth.errorMessage != null) {
      setState(() => _inlineError = auth.errorMessage);
      OAuthHelpers.showMessage(context, auth.errorMessage!);
    }
  }

  Future<void> _doLogin() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent('login_attempt', metadata: {
        'method': 'email',
      });
    } catch (_) {}

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      await VisitorPrefs.clear();
    } else {
      setState(() => _inlineError = auth.errorMessage ?? 'Falha no login.');
    }

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent(success ? 'login_success' : 'login_failed', metadata: {
        'method': 'email',
      });
    } catch (_) {}
  }

  Future<void> _goVisitorMap() async {
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackEvent('visitor_map_from_login');
    } catch (_) {}
    await VisitorPrefs.setVisitorMode(true);
    if (!mounted) return;
    context.go(AppRoutes.mapaVisitante);
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
              AppStyles.logo(size: 88),
              const SizedBox(height: 12),
              Text(
                'Permuta Policial',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plataforma independente e verificada para agentes de segurança',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildTrustRow(context),
              const SizedBox(height: 20),

              // CTA visitante — porta de entrada
              Semantics(
                button: true,
                label: 'Ver o mapa sem cadastro',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButton,
                    onPressed: isLoading ? null : _goVisitorMap,
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: const Text('Ver o mapa sem cadastro'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Entrar na conta',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Social em destaque
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24),
                  label: const Text('Entrar com Google'),
                  style: AppStyles.outlinedButton,
                  onPressed: isLoading
                      ? null
                      : () => OAuthHelpers.loginWithGoogle(
                            context,
                            referralCode: _referralCode,
                          ),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  return SizedBox(
                    width: double.infinity,
                    height: isMobile ? 56 : 50,
                    child: OutlinedButton.icon(
                      icon: Image.asset(
                        'assets/images/microsoft_logo.png',
                        height: 22,
                        width: 22,
                      ),
                      label: Text(
                        isMobile
                            ? 'Entrar com e-mail\ninstitucional'
                            : 'Entrar com e-mail institucional',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isMobile ? 13 : null),
                      ),
                      style: AppStyles.outlinedButton,
                      onPressed: isLoading
                          ? null
                          : () => OAuthHelpers.loginWithMicrosoft(
                                context,
                                referralCode: _referralCode,
                              ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Email/senha colapsável
              InkWell(
                onTap: () => setState(() => _emailExpanded = !_emailExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ou entre com email',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            Icon(
                              _emailExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
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
                          controller: _passwordController,
                          label: 'Senha',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          showPasswordToggle: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _doLogin(),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Senha é obrigatória' : null,
                        ),
                        if (_inlineError != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _inlineError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Semantics(
                          button: true,
                          label: 'Entrar na conta',
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: AppStyles.primaryButton,
                              onPressed: isLoading ? null : _doLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push(AppRoutes.forgotPassword),
                            child: const Text('Esqueceu a senha?'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState:
                    _emailExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : () => context.push(AppRoutes.register),
                child: const Text('Criar conta'),
              ),
              const SizedBox(height: 8),
              _buildInfoBox(context),
            ],
          ),
        );
      },
    );
  }

  /// Linha compacta de selos de confiança, espelhando a seção
  /// "Segurança e confiança" do site (perfis autenticados, conformidade
  /// legal e privacidade controlada).
  Widget _buildTrustRow(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodySmall?.color;

    Widget badge(IconData icon, String label) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: textColor),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        badge(Icons.verified_user_outlined, 'Perfis\nautenticados'),
        badge(Icons.gavel_outlined, 'Sem vínculo\ngovernamental'),
        badge(Icons.privacy_tip_outlined, 'Privacidade\ncontrolada'),
      ],
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recomendamos e-mail institucional (.gov.br) para acesso completo. Contas sem verificação têm acesso limitado.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('Falar com Suporte'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(77)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () => OAuthHelpers.launchExternal(context, 'https://wa.me/555186200626'),
            ),
          ),
        ],
      ),
    );
  }
}