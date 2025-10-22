// /lib/features/splash/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../../../core/config/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_status.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextRoute();
    });
  }

  Future<void> _decideNextRoute() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUrl = web.window.location.href;

    // 1. CASO GOOGLE CALLBACK: Se a URL contém o caminho de callback.
    // A responsabilidade da SplashScreen é simplesmente navegar para a AuthCallbackScreen.
    if (currentUrl.contains(AppRoutes.authCallback)) {
      debugPrint("🔍 Callback detectado. SplashScreen está NAVEGANDO para AuthCallbackScreen.");
      // Usamos pushReplacementNamed para que o usuário não possa "voltar" para a SplashScreen.
      navigator.pushReplacementNamed(AppRoutes.authCallback);
      return; // A lógica para aqui.
    }

    // 2. CASO LOGIN AUTOMÁTICO: Se não for um callback, tentamos o login automático.
    debugPrint("🚀 Tentando login automático...");
    await authProvider.tryAutoLogin();
    
    if (!mounted) return;

    // 3. NAVEGAÇÃO PÓS-LOGIN AUTOMÁTICO:
    if (authProvider.status == AuthStatus.authenticated) {
      debugPrint("✅ Login automático bem-sucedido. Navegando para o Dashboard.");
      navigator.pushReplacementNamed(AppRoutes.dashboard);
    } else {
      // 4. CASO PADRÃO (SEM LOGIN): Se tudo falhar, vai para a Landing Page.
      debugPrint("❌ Nenhum login ativo. Navegando para a Landing Page.");
      navigator.pushReplacementNamed(AppRoutes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A UI da SplashScreen continua sendo apenas uma tela de carregamento universal.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Permuta Policial',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}