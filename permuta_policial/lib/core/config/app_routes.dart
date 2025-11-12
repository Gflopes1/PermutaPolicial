// /lib/core/config/app_routes.dart

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

// Importe todas as telas que serão navegáveis
import '../../features/auth/screens/auth_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/mapa/screens/mapa_screen.dart';
import '../../features/profile/screens/completar_perfil_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/auth/screens/auth_callback_screen.dart';
import '../../features/novos_soldados/screens/novos_soldados_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/profile/screens/meus_dados_screen.dart';


class AppRoutes {
  // Constantes estáticas para os nomes das rotas
  // Isso evita erros de digitação ao chamar Navigator.pushNamed
  static const String splash = '/';
  static const String landing = '/landing';
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String completarPerfil = '/completar-perfil';
  static const String mapa = '/mapa';
  static const String authCallback = '/auth/callback'; 
  static const String novosSoldadosEscolha = '/novos-soldados-escolha';
  static const String admin = '/admin';
  static const String meusDados = '/meus-dados';


  /// Função estática que gera as rotas da aplicação
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());

      case authCallback:
        // Extrai os parâmetros da URL
        final uri = Uri.parse(web.window.location.href);
        final token = uri.queryParameters['token'];
        final completar = uri.queryParameters['completar'] == 'true';
        
        return MaterialPageRoute(
          builder: (_) => AuthCallbackScreen(
            token: token,
            completarPerfil: completar,
          )
        );
       
      case completarPerfil:
        return MaterialPageRoute(builder: (_) => const CompletarPerfilScreen());

      case novosSoldadosEscolha:
        return MaterialPageRoute(builder: (_) => const NovosSoldadosScreen());

      case mapa:
        // Exemplo de como passar argumentos para uma rota de forma segura
        final isVisitor = settings.arguments as bool? ?? false;
        return MaterialPageRoute(builder: (_) => MapaScreen(isVisitorMode: isVisitor));

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminScreen());

      case meusDados:
        return MaterialPageRoute(builder: (_) => const MeusDadosScreen());
      
      case splash:
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}