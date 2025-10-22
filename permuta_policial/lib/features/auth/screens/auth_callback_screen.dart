// /lib/features/auth/screens/auth_callback_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ... outras importações
import '../../../core/config/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../providers/auth_provider.dart';


// O corpo da classe State permanece o mesmo, com os logs que adicionamos antes
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
  
  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    // A lógica com os logs que adicionamos na resposta anterior permanece aqui
    debugPrint("✅ AuthCallbackScreen: Iniciando _handleAuthCallback.");
    final token = widget.token;
    
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Validando token...';
    });
    
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

    debugPrint("🔑 AuthCallbackScreen: Token recebido: ${token.substring(0, 15)}...");

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      setState(() {
        _statusMessage = 'Salvando credenciais...';
      });
      await storage.saveToken(token);
      debugPrint("💾 AuthCallbackScreen: Token salvo no armazenamento.");
      
      setState(() {
        _statusMessage = 'Carregando perfil do usuário...';
      });

      debugPrint("📞 AuthCallbackScreen: Chamando updateAuthenticationState...");
      final success = await authProvider.updateAuthenticationState(token: token);
      debugPrint("🏁 AuthCallbackScreen: updateAuthenticationState retornou: $success");

      if (!mounted) return;

      if (success) {
        debugPrint("👍 AuthCallbackScreen: Sucesso! Verificando para onde navegar...");
        setState(() {
          _statusMessage = 'Redirecionando para o painel...';
        });
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;

        if (widget.completarPerfil || authProvider.user?.unidadeAtualNome == null) {
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
    }
  }


  // --- MUDANÇA APENAS AQUI ---
  @override
  Widget build(BuildContext context) {
    // Esta UI é intencionalmente diferente da SplashScreen para confirmação.
    return Scaffold(
      backgroundColor: Colors.indigo[900], // Cor de fundo diferente
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync_lock, color: Colors.white, size: 50), // Ícone diferente
            const SizedBox(height: 32),
            const Text(
              'Tela de Callback', // Título diferente
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