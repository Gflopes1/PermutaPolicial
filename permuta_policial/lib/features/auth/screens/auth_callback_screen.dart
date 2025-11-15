// /lib/features/auth/screens/auth_callback_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../providers/auth_provider.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String? token;
  final bool completarPerfil;
  const AuthCallbackScreen({
    super.key,
    required this.token,
    this.completarPerfil = false,
  });
  
  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String _statusMessage = 'Processando autenticação...';
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    // ✅ Adiciona delay para garantir que o context está pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isProcessing) {
        _handleAuthCallback();
      }
    });
  }

  Future<void> _handleAuthCallback() async {
    // ✅ Previne execução múltipla
    if (_isProcessing) {
      debugPrint("⚠️ AuthCallbackScreen: Já está processando, ignorando chamada duplicada.");
      return;
    }
    
    _isProcessing = true;
    
    debugPrint("═══════════════════════════════════════");
    debugPrint("✅ AuthCallbackScreen: Iniciando _handleAuthCallback.");
    debugPrint("📍 Token recebido: ${widget.token?.substring(0, 15) ?? 'NULL'}...");
    debugPrint("📍 Completar perfil: ${widget.completarPerfil}");
    debugPrint("═══════════════════════════════════════");
    
    if (!mounted) return;
    
    setState(() {
      _statusMessage = 'Validando token...';
    });
    
    final token = widget.token;
    
    if (token == null || token.isEmpty) {
      debugPrint("❌ AuthCallbackScreen: Token é nulo ou vazio. Redirecionando para /auth.");
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.auth,
          arguments: 'Token não encontrado. Tente novamente.'
        );
      }
      return;
    }

    debugPrint("🔑 AuthCallbackScreen: Token válido: ${token.substring(0, 15)}...");

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!mounted) return;
      
      setState(() {
        _statusMessage = 'Salvando credenciais...';
      });
      
      await storage.saveToken(token);
      debugPrint("💾 AuthCallbackScreen: Token salvo no armazenamento.");
      
      if (!mounted) return;
      
      setState(() {
        _statusMessage = 'Carregando perfil do usuário...';
      });

      debugPrint("📞 AuthCallbackScreen: Chamando updateAuthenticationState...");
      final success = await authProvider.updateAuthenticationState(token: token);
      debugPrint("📊 AuthCallbackScreen: updateAuthenticationState retornou: $success");

      if (!mounted) return;

      if (success) {
        debugPrint("👍 AuthCallbackScreen: Sucesso! Verificando para onde navegar...");
        
        setState(() {
          _statusMessage = 'Autenticação concluída! Redirecionando...';
        });
        
        // ✅ Delay para garantir que o estado está atualizado
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!mounted) return;

        // ✅ Verifica se precisa completar perfil
        final needsCompletion = widget.completarPerfil || 
                                authProvider.user?.unidadeAtualNome == null;
        
        debugPrint("📋 AuthCallbackScreen: Precisa completar perfil? $needsCompletion");
        debugPrint("   - widget.completarPerfil: ${widget.completarPerfil}");
        debugPrint("   - user.unidadeAtualNome: ${authProvider.user?.unidadeAtualNome}");
        
        if (needsCompletion) {
          debugPrint("🚀 AuthCallbackScreen: Navegando para /completar-perfil.");
          Navigator.of(context).pushReplacementNamed(AppRoutes.completarPerfil);
        } else {
          debugPrint("🚀 AuthCallbackScreen: Navegando para /dashboard.");
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      } else {
        debugPrint("👎 AuthCallbackScreen: Falha! (success == false). Navegando para /auth.");
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.auth,
            arguments: authProvider.errorMessage ?? 'Falha ao autenticar.'
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💥 AuthCallbackScreen: ERRO NO CALLBACK: $e');
      debugPrint('   Stack Trace: $stackTrace');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.auth,
          arguments: 'Erro ao processar autenticação: $e'
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync_lock, color: Colors.white, size: 50),
            const SizedBox(height: 32),
            const Text(
              'Processando Autenticação',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 250,
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}