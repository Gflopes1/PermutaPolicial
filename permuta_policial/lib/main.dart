// /lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:permuta_policial/core/config/app_routes.dart';
import 'package:permuta_policial/core/config/app_theme.dart';

// Serviços de Baixo Nível
import 'package:permuta_policial/core/services/storage_service.dart';

// Camada de API (Cliente e Repositórios)
import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/api/repositories/auth_repository.dart';
import 'package:permuta_policial/core/api/repositories/dados_repository.dart';
import 'package:permuta_policial/core/api/repositories/intencoes_repository.dart';
import 'package:permuta_policial/core/api/repositories/mapa_repository.dart';
import 'package:permuta_policial/core/api/repositories/permutas_repository.dart';
import 'package:permuta_policial/core/api/repositories/policiais_repository.dart';
import 'package:permuta_policial/core/api/repositories/parceiros_repository.dart';
// ==========================================================
// 1. IMPORTAR O REPOSITÓRIO EM FALTA
// ==========================================================
import 'package:permuta_policial/core/api/repositories/novos_soldados_repository.dart';
import 'package:permuta_policial/core/api/repositories/admin_repository.dart';

// Camada de Estado (Providers)
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/dashboard/providers/dashboard_provider.dart';
import 'package:permuta_policial/features/dados/providers/dados_provider.dart';
import 'package:permuta_policial/features/mapa/providers/mapa_provider.dart';
import 'package:permuta_policial/features/profile/providers/profile_provider.dart';
import 'package:permuta_policial/features/novos_soldados/providers/novos_soldados_provider.dart';
import 'package:permuta_policial/features/admin/providers/admin_provider.dart';


void main() {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // Apenas chamamos runApp, sem nenhuma lógica de rota aqui.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- NÍVEL 1: SERVIÇOS DE BAIXO NÍVEL ---
        Provider<StorageService>(create: (_) => StorageService()),
        
        // --- NÍVEL 2: CAMADA DE DADOS (API) ---
        Provider<ApiClient>(
          create: (context) => ApiClient(context.read<StorageService>()),
        ),
        // Repositórios dependem do ApiClient.
        Provider<AuthRepository>(
          create: (context) => AuthRepository(context.read<ApiClient>(), context.read<StorageService>()),
        ),
        Provider<PoliciaisRepository>(
          create: (context) => PoliciaisRepository(context.read<ApiClient>()),
        ),
        Provider<IntencoesRepository>(
          create: (context) => IntencoesRepository(context.read<ApiClient>()),
        ),
        Provider<PermutasRepository>(
          create: (context) => PermutasRepository(context.read<ApiClient>()),
        ),
        Provider<DadosRepository>(
          create: (context) => DadosRepository(context.read<ApiClient>()),
        ),
        Provider<ParceirosRepository>(
          create: (context) => ParceirosRepository(context.read<ApiClient>()),
        ),
         Provider<MapaRepository>(
          create: (context) => MapaRepository(context.read<ApiClient>()),
        ),
        // ==========================================================
        // 2. ADICIONAR O REPOSITÓRIO EM FALTA AQUI
        // ==========================================================
        Provider<NovosSoldadosRepository>(
          create: (context) => NovosSoldadosRepository(context.read<ApiClient>()),
        ),
        Provider<AdminRepository>(
          create: (context) => AdminRepository(context.read<ApiClient>()),
        ),

        // --- NÍVEL 3: CAMADA DE ESTADO (PROVIDERS) ---
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<AuthRepository>(), ctx.read<PoliciaisRepository>()),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (ctx) => DashboardProvider(
            ctx.read<PoliciaisRepository>(),
            ctx.read<IntencoesRepository>(),
            ctx.read<PermutasRepository>(),
            ctx.read<StorageService>(),
            ctx.read<ParceirosRepository>(),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (ctx) => ProfileProvider(ctx.read<PoliciaisRepository>(), ctx.read<DadosRepository>()),
        ),
        // Esta linha agora funciona, porque o NovosSoldadosRepository foi fornecido acima
        ChangeNotifierProvider(create: (context) => NovosSoldadosProvider(
          context.read<NovosSoldadosRepository>(),
        )),
        ChangeNotifierProvider<DadosProvider>(
          create: (ctx) => DadosProvider(ctx.read<DadosRepository>()),
        ),
        ChangeNotifierProvider<MapaProvider>(
          create: (ctx) => MapaProvider(ctx.read<MapaRepository>(), ctx.read<DadosRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AdminProvider(ctx.read<AdminRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Permuta Policial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}