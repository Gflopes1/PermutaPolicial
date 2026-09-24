// /lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:permuta_policial/core/config/app_router.dart' show createAppRouter, navigatorKey;
import 'package:permuta_policial/core/config/app_theme.dart';
import 'package:permuta_policial/core/config/app_config.dart';
import 'package:permuta_policial/core/api/api_client.dart';

// Serviços de Baixo Nível
import 'package:permuta_policial/core/services/storage_service.dart';

// Camada de API (Cliente e Repositórios)
import 'package:permuta_policial/core/api/repositories/auth_repository.dart';
import 'package:permuta_policial/core/api/repositories/dados_repository.dart';
import 'package:permuta_policial/core/api/repositories/intencoes_repository.dart';
import 'package:permuta_policial/core/api/repositories/mapa_repository.dart';
import 'package:permuta_policial/core/api/repositories/permutas_repository.dart';
import 'package:permuta_policial/core/api/repositories/permutas_inteligentes_repository.dart';
import 'package:permuta_policial/core/api/repositories/policiais_repository.dart';
import 'package:permuta_policial/core/api/repositories/parceiros_repository.dart';
import 'package:permuta_policial/core/api/repositories/consultoria_juridica_repository.dart';
import 'package:permuta_policial/core/api/repositories/admin_repository.dart';
import 'package:permuta_policial/core/api/repositories/analytics_repository.dart';
import 'package:permuta_policial/core/api/repositories/editais_repository.dart';
import 'package:permuta_policial/core/api/repositories/chat_repository.dart';
import 'package:permuta_policial/core/api/repositories/forum_repository.dart';
import 'package:permuta_policial/core/api/repositories/notificacoes_repository.dart';
import 'package:permuta_policial/core/api/repositories/configuracoes_repository.dart';
import 'package:permuta_policial/core/api/repositories/work_repository.dart';
import 'package:permuta_policial/core/api/repositories/presets_repository.dart';
import 'package:permuta_policial/core/api/repositories/salary_repository.dart';
import 'package:permuta_policial/core/api/repositories/questions_repository.dart';
import 'package:permuta_policial/core/api/repositories/payments_repository.dart';
import 'package:permuta_policial/core/api/repositories/mapa_tatico_repository.dart';
import 'package:permuta_policial/core/api/repositories/referral_repository.dart';
import 'package:permuta_policial/core/api/repositories/verificacao_ocr_repository.dart';

// Serviços
import 'package:permuta_policial/core/services/socket_service.dart';
import 'package:permuta_policial/core/services/version_service.dart';
import 'package:permuta_policial/core/services/analytics_service.dart';
import 'package:permuta_policial/core/services/atualizacao_service.dart';
import 'package:permuta_policial/core/services/announcement_service.dart';
import 'package:permuta_policial/core/services/referral_storage_service.dart';
import 'package:permuta_policial/core/services/connectivity_service.dart';
import 'package:permuta_policial/core/services/push_notification_service.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

// Banco de Dados
import 'package:permuta_policial/core/database/database.dart';

// Camada de Estado (Providers)
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/dashboard/providers/dashboard_provider.dart';
import 'package:permuta_policial/features/permutas/providers/permutas_inteligentes_provider.dart';
import 'package:permuta_policial/features/dados/providers/dados_provider.dart';
import 'package:permuta_policial/features/mapa/providers/mapa_provider.dart';
import 'package:permuta_policial/features/profile/providers/profile_provider.dart';
import 'package:permuta_policial/features/editais/providers/editais_hub_provider.dart';
import 'package:permuta_policial/features/chat/providers/chat_provider.dart';
import 'package:permuta_policial/features/forum/providers/forum_provider.dart';
import 'package:permuta_policial/features/marketplace/providers/marketplace_provider.dart';
import 'package:permuta_policial/core/api/repositories/marketplace_repository.dart';
import 'package:permuta_policial/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:permuta_policial/features/questions/providers/questions_provider.dart';
import 'package:permuta_policial/features/referral/providers/referral_provider.dart';
import 'package:permuta_policial/shared/widgets/web_push_permission_banner.dart';
import 'package:permuta_policial/shared/widgets/web_update_banner.dart';
import 'package:permuta_policial/core/lifecycle/app_lifecycle_handler.dart';
import 'package:permuta_policial/core/config/webview_platform_register_stub.dart'
    if (dart.library.html) 'package:permuta_policial/core/config/webview_platform_register_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppTheme.dark.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            kIsWeb
                ? 'Algo deu errado. Recarregue a página para continuar.'
                : 'Algo deu errado. Reinicie o app para continuar.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  };

  registerWebViewPlatform();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Configura o GlobalKey do Navigator para uso global (ex: modal Premium)
  ApiClient.setNavigatorKey(navigatorKey);

  // runApp imediato: tudo que não é essencial ao primeiro frame fica para depois.
  runApp(const MyApp());

  // Pós-frame: logging e deep links não atrasam o primeiro frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (kDebugMode) {
      AppConfig.logEnvironment();
    }
    if (!kIsWeb) {
      _setupDeepLinks();
    }
  });
}

/// Configura tratamento de deep links customizados (permutapolicial://)
void _setupDeepLinks() {
  final appLinks = AppLinks();
  
  // Trata deep link inicial (quando app é aberto via link)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });
  
  // Trata deep links quando app já está aberto
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  }, onError: (err) {
    debugPrint('Erro ao processar deep link: $err');
  });
}

/// Processa deep links e navega para a rota correta
void _handleDeepLink(Uri uri, {int attempt = 0}) {
  const maxAttempts = 5;
  debugPrint('🔗 Deep link recebido: $uri');
  
  if (uri.scheme == 'permutapolicial' && uri.host == 'auth' && uri.pathSegments.contains('callback')) {
    final token = uri.queryParameters['token'];
    final completar = uri.queryParameters['completar'] == 'true';
    final error = uri.queryParameters['error'];
    
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (attempt >= maxAttempts) {
        debugPrint('⚠️ Deep link: context indisponível após $maxAttempts tentativas');
        return;
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleDeepLink(uri, attempt: attempt + 1);
      });
      return;
    }
    
    if (error != null) {
      final message = uri.queryParameters['message'];
      final query = message != null && message.isNotEmpty
          ? 'error=${Uri.encodeComponent(error)}&message=${Uri.encodeComponent(message)}'
          : 'error=${Uri.encodeComponent(error)}';
      context.go('/auth?$query');
    } else if (uri.queryParameters['code'] != null) {
      final code = uri.queryParameters['code']!;
      final next = uri.queryParameters['next'];
      final query = StringBuffer('/auth/callback?code=${Uri.encodeComponent(code)}');
      if (completar) query.write('&completar=true');
      if (next != null && next.isNotEmpty) {
        query.write('&next=${Uri.encodeComponent(next)}');
      }
      context.go(query.toString());
    } else if (token != null) {
      final decodedToken = Uri.decodeComponent(token);
      context.go('/auth/callback?token=${Uri.encodeComponent(decodedToken)}${completar ? '&completar=true' : ''}');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- NÍVEL 1: SERVIÇOS DE BAIXO NÍVEL ---
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<VersionService>(
          create: (context) => VersionService(context.read<StorageService>()),
        ),
        
        // --- NÍVEL 1.5: BANCO DE DADOS LOCAL E SERVIÇOS ---
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
        ),
        Provider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
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
        Provider<PermutasInteligentesRepository>(
          create: (context) => PermutasInteligentesRepository(context.read<ApiClient>()),
        ),
        Provider<DadosRepository>(
          create: (context) => DadosRepository(context.read<ApiClient>()),
        ),
        Provider<ParceirosRepository>(
          create: (context) => ParceirosRepository(context.read<ApiClient>()),
        ),
        Provider<ConsultoriaJuridicaRepository>(
          create: (context) => ConsultoriaJuridicaRepository(context.read<ApiClient>()),
        ),
        Provider<AdminRepository>(
          create: (context) => AdminRepository(context.read<ApiClient>()),
        ),
        Provider<VerificacaoOcrRepository>(
          create: (context) => VerificacaoOcrRepository(context.read<ApiClient>()),
        ),
        Provider<AnalyticsRepository>(
          create: (context) => AnalyticsRepository(context.read<ApiClient>()),
        ),
         Provider<MapaRepository>(
          create: (context) => MapaRepository(context.read<ApiClient>()),
        ),
        Provider<EditaisRepository>(
          create: (context) => EditaisRepository(context.read<ApiClient>()),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepository(context.read<ApiClient>()),
        ),
        Provider<ForumRepository>(
          create: (context) => ForumRepository(context.read<ApiClient>()),
        ),
        Provider<MarketplaceRepository>(
          create: (context) => MarketplaceRepository(context.read<ApiClient>()),
        ),
        Provider<ConfiguracoesRepository>(
          create: (context) => ConfiguracoesRepository(context.read<ApiClient>()),
        ),
        Provider<AtualizacaoService>(
          create: (context) => AtualizacaoService(context.read<ConfiguracoesRepository>()),
        ),
        Provider<ReferralRepository>(
          create: (context) => ReferralRepository(context.read<ApiClient>()),
        ),
        Provider<ReferralStorageService>(
          create: (_) => ReferralStorageService(),
        ),
        Provider<AnnouncementService>(
          create: (context) => AnnouncementService(
            context.read<ConfiguracoesRepository>(),
            referralRepository: context.read<ReferralRepository>(),
          ),
        ),
        Provider<NotificacoesRepository>(
          create: (context) => NotificacoesRepository(context.read<ApiClient>()),
        ),
        Provider<WorkRepository>(
          create: (context) => WorkRepository(context.read<ApiClient>()),
        ),
        Provider<PresetsRepository>(
          create: (context) => PresetsRepository(context.read<ApiClient>()),
        ),
        Provider<SalaryRepository>(
          create: (context) => SalaryRepository(context.read<ApiClient>()),
        ),
        Provider<QuestionsRepository>(
          create: (context) => QuestionsRepository(context.read<ApiClient>()),
        ),
        Provider<PaymentsRepository>(
          create: (context) => PaymentsRepository(context.read<ApiClient>()),
        ),
        Provider<MapaTaticoRepository>(
          create: (context) => MapaTaticoRepository(context.read<ApiClient>()),
        ),
        Provider<SocketService>(
          create: (context) => SocketService(context.read<StorageService>()),
        ),
        Provider<AnalyticsService>(
          create: (context) => AnalyticsService(context.read<ApiClient>()),
        ),
        Provider<PushNotificationService>(
          create: (context) => PushNotificationService(context.read<ApiClient>()),
        ),
        // --- NÍVEL 3: CAMADA DE ESTADO (PROVIDERS) ---
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            ctx.read<AuthRepository>(),
            ctx.read<PoliciaisRepository>(),
            ctx.read<AnalyticsService>(),
            ctx.read<StorageService>(),
            ctx.read<PushNotificationService>(),
          ),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (ctx) => DashboardProvider(
            ctx.read<PoliciaisRepository>(),
            ctx.read<IntencoesRepository>(),
            ctx.read<PermutasRepository>(),
            ctx.read<StorageService>(),
            ctx.read<ParceirosRepository>(),
            ctx.read<ConsultoriaJuridicaRepository>(),
            ctx.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider<PermutasInteligentesProvider>(
          create: (ctx) => PermutasInteligentesProvider(
            ctx.read<PermutasInteligentesRepository>(),
            ctx.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (ctx) => ProfileProvider(
            ctx.read<PoliciaisRepository>(),
            ctx.read<DadosRepository>(),
            ctx.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => EditaisHubProvider(
          context.read<EditaisRepository>(),
        )),
        ChangeNotifierProvider<DadosProvider>(
          create: (ctx) => DadosProvider(ctx.read<DadosRepository>()),
        ),
        ChangeNotifierProvider<MapaProvider>(
          create: (ctx) => MapaProvider(
            ctx.read<MapaRepository>(),
            ctx.read<DadosRepository>(),
            ctx.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<ChatRepository>(), ctx.read<SocketService>()),
        ),
        ChangeNotifierProvider<ForumProvider>(
          create: (ctx) => ForumProvider(ctx.read<ForumRepository>()),
        ),
        ChangeNotifierProvider<MarketplaceProvider>(
          create: (ctx) => MarketplaceProvider(
            ctx.read<MarketplaceRepository>(),
            ctx.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider<NotificacoesProvider>(
          create: (ctx) => NotificacoesProvider(
            ctx.read<NotificacoesRepository>(),
          ),
        ),
        ChangeNotifierProvider<QuestionsProvider>(
          create: (ctx) => QuestionsProvider(ctx.read<QuestionsRepository>()),
        ),
        ChangeNotifierProvider<ReferralProvider>(
          create: (ctx) => ReferralProvider(
            ctx.read<ReferralRepository>(),
            ctx.read<ReferralStorageService>(),
          ),
        ),
      ],
      child: const AppLifecycleHandler(
        child: _AppWithRouter(),
      ),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kIsWeb) return;
      final push = context.read<PushNotificationService>();
      await push.initialize();
    });
  }

  /// Recria o GoRouter após hot reload para refletir mudanças nas rotas.
  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode) {
      _router = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    ApiClient.onSessionExpired = authProvider.handleSessionExpired;
    _router ??= createAppRouter(authProvider);

    Widget wrapChild(BuildContext context, Widget? child) {
      final content = child ?? const AppBootPlaceholder();
      final media = MediaQuery.of(context);
      final scaled = MediaQuery(
        data: media.copyWith(
          textScaler: media.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.45,
          ),
        ),
        child: content,
      );
      if (!kIsWeb) return scaled;
      return WebUpdateOverlay(
        child: WebPushPermissionOverlay(child: scaled),
      );
    }

    return MaterialApp.router(
      title: 'Permuta Policial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router!,
      builder: wrapChild,
    );
  }
}