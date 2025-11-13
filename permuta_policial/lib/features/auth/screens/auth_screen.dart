// /lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permuta_policial/core/api/repositories/dados_repository.dart';
import 'package:permuta_policial/core/config/app_routes.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/providers/auth_status.dart';
import 'package:permuta_policial/shared/widgets/custom_dropdown_search.dart';
import 'package:permuta_policial/shared/widgets/custom_text_field.dart';
import 'package:permuta_policial/core/api/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // --- STATE MANAGEMENT ---
  String _uiState = 'login';
  
  // --- CONTROLLERS ---
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();
  final _nomeRegistoController = TextEditingController();
  final _idRegistoController = TextEditingController();
  final _emailRegistoController = TextEditingController();
  final _qsoRegistoController = TextEditingController();
  final _senhaRegistoController = TextEditingController();
  final _confirmarSenhaRegistoController = TextEditingController();
  dynamic _forcaSelecionadaRegisto;
  bool _consentimentoLGPD = false;
  final _codigoConfirmacaoController = TextEditingController();
  final _emailRecuperarController = TextEditingController();
  final _codigoRecuperarController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();

  // --- FORM KEYS ---
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegisto = GlobalKey<FormState>();
  final _formKeyConfirmarEmail = GlobalKey<FormState>();
  final _formKeyRecuperar1 = GlobalKey<FormState>();
  final _formKeyRecuperar2 = GlobalKey<FormState>();

  // --- LIFECYCLE ---
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    Provider.of<AuthProvider>(context, listen: false).removeListener(_onAuthStateChanged);
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _nomeRegistoController.dispose();
    _idRegistoController.dispose();
    _emailRegistoController.dispose();
    _qsoRegistoController.dispose();
    _senhaRegistoController.dispose();
    _confirmarSenhaRegistoController.dispose();
    _codigoConfirmacaoController.dispose();
    _emailRecuperarController.dispose();
    _codigoRecuperarController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }
  
  // --- LISTENERS ---
  void _onAuthStateChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      if (authProvider.user?.unidadeAtualNome == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.completarPerfil);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    }
    if (authProvider.status == AuthStatus.unauthenticated && authProvider.errorMessage != null) {
      _showMessage(authProvider.errorMessage!, isSuccess: false);
    }
  }

  // --- ACTIONS ---
  Future<void> _doLogin() async {
    if (!_formKeyLogin.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(_emailLoginController.text.trim(), _passwordLoginController.text);
  }
  
  Future<void> _doRegister() async {
    if (!_formKeyRegisto.currentState!.validate()) return;
    if (_forcaSelecionadaRegisto == null) { _showMessage('Por favor, selecione sua força policial.', isSuccess: false); return; }
    if (!_consentimentoLGPD) { _showMessage('Você precisa aceitar os Termos de Uso.', isSuccess: false); return; }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = {
      'nome': _nomeRegistoController.text.trim(), 'id_funcional': _idRegistoController.text.trim(),
      'forca_id': _forcaSelecionadaRegisto.id, 'email': _emailRegistoController.text.trim(),
      'qso': _qsoRegistoController.text.trim(), 'senha': _senhaRegistoController.text,
    };
    final successMessage = await authProvider.register(userData);
    if (successMessage != null) {
      _showMessage(successMessage, isSuccess: true);
      setState(() => _uiState = 'confirmar_email');
    }
  }

  Future<void> _doConfirmEmail() async {
    if (!_formKeyConfirmarEmail.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.confirmEmail(_emailRegistoController.text.trim(), _codigoConfirmacaoController.text.trim());
    if (success) {
      _showMessage('Email confirmado com sucesso! Você já pode fazer login.', isSuccess: true);
      setState(() => _uiState = 'login');
    }
  }

  Future<void> _doRequestReset() async {
    if (!_formKeyRecuperar1.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestPasswordReset(_emailRecuperarController.text.trim());
    if (success) {
      _showMessage('Se o email estiver cadastrado, um código foi enviado.', isSuccess: true);
      setState(() => _uiState = 'recuperar_passo2');
    }
  }

  Future<void> _doValidateAndReset() async {
    if (!_formKeyRecuperar2.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tempToken = await authProvider.validateResetCode(_emailRecuperarController.text.trim(), _codigoRecuperarController.text.trim());
    if (tempToken != null) {
      final success = await authProvider.resetPassword(tempToken, _novaSenhaController.text);
      if (success) {
        _showMessage('Senha redefinida com sucesso!', isSuccess: true);
        setState(() => _uiState = 'login');
      }
    }
  }

  Future<void> _doLoginComMicrosoft() async {
    debugPrint('🔵 Iniciando login com Microsoft...');
    final baseUrl = Provider.of<ApiClient>(context, listen: false).baseUrl;
    final microsoftAuthUrl = Uri.parse('$baseUrl/api/auth/microsoft');

    if (!await launchUrl(microsoftAuthUrl, webOnlyWindowName: '_self')) {
      _showMessage('Não foi possível iniciar o login com Microsoft.');
    }
  }

  // --- HELPERS ---
  void _showMessage(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isSuccess ? Colors.green.shade600 : Theme.of(context).colorScheme.error));
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) _showMessage('Não foi possível abrir o link.');
  }
  
  Future<void> _doLoginComGoogle() async {
    debugPrint('🔵 Iniciando login com Google...');
    final baseUrl = Provider.of<ApiClient>(context, listen: false).baseUrl;
    final googleAuthUrl = Uri.parse('$baseUrl/api/auth/google');
    
    debugPrint('🔗 URL do Google: $googleAuthUrl');
    
    if (!await launchUrl(googleAuthUrl, webOnlyWindowName: '_self')) {
      debugPrint('❌ Falha ao abrir URL do Google');
      _showMessage('Não foi possível iniciar o login com Google.');
    } else {
      debugPrint('✅ Redirecionando para Google...');
    }
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.status == AuthStatus.authenticating;
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 8, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300), 
                          child: _buildCurrentForm(isLoading)
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentForm(bool isLoading) {
    switch (_uiState) {
      case 'registo': return _buildRegisterForm(isLoading);
      case 'confirmar_email': return _buildConfirmEmailForm(isLoading);
      case 'recuperar_passo1': return _buildRequestResetForm(isLoading);
      case 'recuperar_passo2': return _buildResetPasswordForm(isLoading);
      case 'login': default: return _buildLoginForm(isLoading);
    }
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _formKeyLogin,
      child: Column(
        key: const ValueKey('login_form'), 
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_tatico.png', height: 100),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailLoginController, 
            label: 'Email', 
            prefixIcon: Icons.email, 
            keyboardType: TextInputType.emailAddress, 
            validator: (v) => (v?.isEmpty ?? true) ? 'Email é obrigatório' : null
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordLoginController, 
            label: 'Senha', 
            prefixIcon: Icons.lock, 
            obscureText: true, 
            validator: (v) => (v?.isEmpty ?? true) ? 'Senha é obrigatória' : null
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: isLoading ? null : _doLogin, 
              child: isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Entrar')
            )
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'OU', 
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24),
              label: const Text(
                'Entrar com Google', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : _doLoginComGoogle,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: Image.asset('assets/images/microsoft_logo.png', height: 22, width: 22),
              label: const Text(
                'Entrar com Email Funcional (Recomendado)', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : _doLoginComMicrosoft,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: isLoading ? null : () => setState(() => _uiState = 'registo'), 
                child: const Text('Criar conta')
              ),
              TextButton(
                onPressed: isLoading ? null : () => setState(() => _uiState = 'recuperar_passo1'), 
                child: const Text('Esqueceu a senha?')
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(77)
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline, 
                      size: 20, 
                      color: Theme.of(context).colorScheme.primary
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Apenas emails com domínios da segurança pública são permitidos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color
                        )
                      )
                    ),
                  ]
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Falar com Suporte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withAlpha(77)
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _launchURL('https://wa.me/555186200626'),
                  ),
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    return Form(
      key: _formKeyRegisto,
      child: Column(
        key: const ValueKey('register_form'), 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Criar Nova Conta', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _nomeRegistoController, 
            label: 'Nome Completo', 
            prefixIcon: Icons.person, 
            validator: (v) => (v?.isEmpty ?? true) ? 'Nome é obrigatório' : null
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _idRegistoController, 
            label: 'ID Funcional', 
            prefixIcon: Icons.badge, 
            validator: (v) => (v?.isEmpty ?? true) ? 'ID Funcional é obrigatório' : null
          ),
          const SizedBox(height: 16),
          CustomDropdownSearch<dynamic>(
            label: 'Força Policial', 
            asyncItems: (_) => dadosRepo.getForcas(), 
            itemAsString: (item) => "${item.sigla} - ${item.nome}", 
            onChanged: (value) => setState(() => _forcaSelecionadaRegisto = value)
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailRegistoController, 
            label: 'Email', 
            prefixIcon: Icons.email, 
            keyboardType: TextInputType.emailAddress, 
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Email é obrigatório';
              if (!v!.contains('@')) return 'Email inválido';
              return null;
            }
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(77)
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  size: 20, 
                  color: Theme.of(context).colorScheme.primary
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Apenas emails com domínios da segurança pública são permitidos. Isso ajuda a manter os dados seguros e exclusivos para profissionais da área.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color
                    )
                  )
                ),
              ]
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _qsoRegistoController, 
            label: 'Telefone', 
            prefixIcon: Icons.phone, 
            keyboardType: TextInputType.phone, 
            validator: (v) => (v?.isEmpty ?? true) ? 'Telefone é obrigatório' : null
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _senhaRegistoController, 
            label: 'Senha', 
            prefixIcon: Icons.lock, 
            obscureText: true, 
            validator: (v) { 
              if (v == null || v.length < 8) return 'Mínimo 8 caracteres'; 
              return null; 
            }
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmarSenhaRegistoController, 
            label: 'Confirmar Senha', 
            prefixIcon: Icons.lock_outline, 
            obscureText: true, 
            validator: (v) => v != _senhaRegistoController.text ? 'As senhas não coincidem' : null
          ),
          CheckboxListTile(
            title: const Text('Li e aceito os Termos de Uso.', style: TextStyle(fontSize: 14)), 
            value: _consentimentoLGPD, 
            onChanged: (value) => setState(() => _consentimentoLGPD = value ?? false), 
            controlAffinity: ListTileControlAffinity.leading, 
            contentPadding: EdgeInsets.zero
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: isLoading ? null : _doRegister, 
              child: isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Criar Conta')
            )
          ),
          TextButton(
            onPressed: isLoading ? null : () => setState(() => _uiState = 'login'), 
            child: const Text('Já tenho uma conta')
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmEmailForm(bool isLoading) {
    return Form(
      key: _formKeyConfirmarEmail,
      child: Column(
        key: const ValueKey('confirm_form'), 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Verificar Email', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text('Enviamos um código de 6 dígitos para ${_emailRegistoController.text}.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _codigoConfirmacaoController, 
            label: 'Código de 6 dígitos', 
            prefixIcon: Icons.pin, 
            keyboardType: TextInputType.number, 
            validator: (v) => (v?.length ?? 0) != 6 ? 'Código inválido' : null
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: isLoading ? null : _doConfirmEmail, 
              child: isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Confirmar')
            )
          ),
          TextButton(
            onPressed: isLoading ? null : () => setState(() => _uiState = 'login'), 
            child: const Text('Voltar ao Login')
          ),
        ],
      ),
    );
  }

  Widget _buildRequestResetForm(bool isLoading) {
    return Form(
      key: _formKeyRecuperar1,
      child: Column(
        key: const ValueKey('req_reset_form'), 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Recuperar Senha', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Informe seu e-mail para receber o código de recuperação.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailRecuperarController, 
            label: 'Email', 
            prefixIcon: Icons.email, 
            keyboardType: TextInputType.emailAddress, 
            validator: (v) => (v?.isEmpty ?? true) ? 'Email é obrigatório' : null
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: isLoading ? null : _doRequestReset, 
              child: isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Enviar Código')
            )
          ),
          TextButton(
            onPressed: isLoading ? null : () => setState(() => _uiState = 'login'), 
            child: const Text('Voltar ao Login')
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm(bool isLoading) {
    return Form(
      key: _formKeyRecuperar2,
      child: Column(
        key: const ValueKey('reset_form'), 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Redefinir Senha', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _codigoRecuperarController, 
            label: 'Código de Recuperação', 
            prefixIcon: Icons.pin, 
            keyboardType: TextInputType.number, 
            validator: (v) => (v?.length ?? 0) != 6 ? 'Código inválido' : null
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _novaSenhaController, 
            label: 'Nova Senha', 
            prefixIcon: Icons.lock, 
            obscureText: true, 
            validator: (v) => (v?.length ?? 0) < 8 ? 'Mínimo 8 caracteres' : null
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmarNovaSenhaController, 
            label: 'Confirmar Nova Senha', 
            prefixIcon: Icons.lock_outline, 
            obscureText: true, 
            validator: (v) => v != _novaSenhaController.text ? 'As senhas não coincidem' : null
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: isLoading ? null : _doValidateAndReset, 
              child: isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : const Text('Redefinir Senha')
            )
          ),
          TextButton(
            onPressed: isLoading ? null : () => setState(() => _uiState = 'login'), 
            child: const Text('Voltar ao Login')
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center, 
          spacing: 16, 
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/termos.html'), 
              child: const Text('Termos de Uso', style: TextStyle(color: Colors.white70, fontSize: 13))
            ),
            const Text('|', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/privacidade.html'), 
              child: const Text('Política de Privacidade', style: TextStyle(color: Colors.white70, fontSize: 13))
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'contato@permutapolicial.com.br',
          style: TextStyle(
            color: Colors.white70.withAlpha(179),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}