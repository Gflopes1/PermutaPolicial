// /lib/core/config/app_router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'route_guards.dart';
import '../utils/platform_utils.dart';
import '../widgets/deferred_screen.dart';
import 'route_scoped_providers.dart';
import '../../features/forum/screens/forum_list_screen.dart' deferred as forum_list;

// Telas do caminho crítico (cold start) — eager
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_wizard_screen.dart';
import '../../features/auth/screens/confirm_email_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_entry_screen.dart';
import '../../features/mapa/screens/mapa_screen.dart';
import '../../features/profile/screens/completar_perfil_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/auth/screens/auth_callback_screen.dart';
import '../../features/referral/screens/referral_landing_screen.dart';

// Telas secundárias — deferred (reduz main.dart.js no web)
import '../../features/editais/screens/editais_hub_screen.dart' deferred as editais_hub;
import '../../features/editais/screens/edital_detalhe_screen.dart' deferred as edital_detalhe;
import '../../features/editais/screens/edital_consulta_visitante_screen.dart'
    deferred as edital_consulta;
import '../../features/admin/screens/admin_screen.dart' deferred as admin;
import '../../features/marketplace/screens/marketplace_screen.dart' deferred as marketplace;
import '../../features/notificacoes/screens/notificacoes_screen.dart' deferred as notificacoes;
import '../../features/profile/screens/profile_screen.dart' deferred as profile;
import '../../features/permutas/screens/permutas_unificadas_screen.dart' deferred as permutas;
import '../../features/calendar/screens/calendar_screen.dart' deferred as calendar;
import '../../features/questions/screens/questions_list_screen.dart' deferred as questions_list;
import '../../features/questions/screens/question_detail_screen.dart' deferred as question_detail;
import '../../features/questions/screens/question_comments_screen.dart'
    deferred as question_comments;
import '../../features/questions/screens/simulado_create_screen.dart' deferred as simulado_create;
import '../../features/questions/screens/simulado_play_screen.dart' deferred as simulado_play;
import '../../features/questions/screens/simulado_result_screen.dart' deferred as simulado_result;
import '../../features/questions/screens/practice_screen.dart' deferred as practice;
import '../../features/questions/screens/practice_history_screen.dart' deferred as practice_history;
import '../../features/questions/screens/questions_admin_screen.dart' deferred as questions_admin;
import '../../features/questions/screens/questions_list_all_screen.dart'
    deferred as questions_list_all;
import '../../features/chat/screens/chat_conversa_screen.dart' deferred as chat_conversa;
import '../../features/forum/screens/forum_topico_screen.dart' deferred as forum_topico;
import '../../features/forum/screens/forum_moderacao_screen.dart' deferred as forum_moderacao;
import '../../features/forum/screens/forum_create_topico_screen.dart' deferred as forum_create;
import '../../features/premium/screens/premium_success_screen.dart' deferred as premium_success;
import '../../features/mapa_tatico/screens/mapa_tatico_screen.dart' deferred as mapa_tatico;
import '../../features/mapa_tatico/screens/mapa_tatico_intelligence_screen.dart'
    deferred as mapa_tatico_intel;
import '../../features/mapa_tatico/screens/detalhe_ponto_screen.dart' deferred as mapa_tatico_ponto;
import '../../features/consultoria_juridica/screens/consultoria_advogado_detalhe_screen.dart'
    deferred as consultoria_detalhe;
import '../../features/referral/screens/referral_screen.dart' deferred as referral;
import '../../features/verificacao/screens/verificacao_documento_screen.dart'
    deferred as verificacao_doc;
import '../../features/verificacao/screens/verificacao_barrier_screen.dart'
    deferred as verificacao_barrier;

// GlobalKey para acesso global ao Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Widget _defer(
  Future<void> Function() loadLibrary,
  Widget Function() builder,
) {
  return DeferredScreen(loadLibrary: loadLibrary, builder: builder);
}

String _resolveInitialLocation() {
  if (!kIsWeb) return '/';
  final pathname = getPathname();
  final search = getSearch();
  if (pathname.isEmpty || pathname == '/') return '/';
  return search.isNotEmpty ? '$pathname$search' : pathname;
}

/// Configuração do GoRouter para navegação declarativa
GoRouter createAppRouter(AuthProvider authProvider) => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: _resolveInitialLocation(),
  debugLogDiagnostics: kDebugMode,
  refreshListenable: authProvider,
  redirect: (context, state) => authRedirect(authProvider, state),
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/landing',
      name: 'landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/auth/register',
      name: 'register',
      builder: (context, state) => const RegisterWizardScreen(),
    ),
    GoRoute(
      path: '/r/:code',
      name: 'referral-landing',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return ReferralLandingScreen(code: code);
      },
    ),
    GoRoute(
      path: '/referral',
      name: 'referral',
      builder: (context, state) => _defer(
        referral.loadLibrary,
        () => referral.ReferralScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/confirm-email',
      name: 'confirmEmail',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return ConfirmEmailScreen(email: email);
      },
    ),
    GoRoute(
      path: '/auth/forgot-password',
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/callback',
      name: 'authCallback',
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];
        final rawToken = state.uri.queryParameters['token'];
        final token = rawToken != null ? Uri.decodeComponent(rawToken) : null;
        final completar = state.uri.queryParameters['completar'] == 'true';
        final next = state.uri.queryParameters['next'];

        return AuthCallbackScreen(
          code: code,
          token: token,
          completarPerfil: completar,
          nextPath: next,
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardEntryScreen(),
    ),
    GoRoute(
      path: '/completar-perfil',
      name: 'completarPerfil',
      builder: (context, state) => const CompletarPerfilScreen(),
    ),
    GoRoute(
      path: '/mapa/visitante',
      name: 'mapaVisitante',
      builder: (context, state) => const MapaScreen(isVisitorMode: true),
    ),
    GoRoute(
      path: '/mapa',
      name: 'mapa',
      builder: (context, state) {
        final visitor = state.uri.queryParameters['visitor'];
        final isVisitor = visitor == 'true' || visitor == '1';
        return MapaScreen(isVisitorMode: isVisitor);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => RouteScopedProviders.mapaTatico(context, child),
      routes: [
        GoRoute(
          path: '/mapa-tatico',
          name: 'mapaTatico',
          builder: (context, state) => _defer(
            mapa_tatico.loadLibrary,
            () => mapa_tatico.MapaTaticoScreen(),
          ),
        ),
        GoRoute(
          path: '/mapa-tatico/inteligencia',
          name: 'mapaTaticoInteligencia',
          builder: (context, state) => _defer(
            mapa_tatico_intel.loadLibrary,
            () => mapa_tatico_intel.MapaTaticoIntelligenceScreen(),
          ),
        ),
        GoRoute(
          path: '/mapa-tatico/ponto/:pointId',
          name: 'mapaTaticoPonto',
          builder: (context, state) {
            final pointId = int.tryParse(state.pathParameters['pointId'] ?? '');
            if (pointId == null) {
              return _defer(
                mapa_tatico.loadLibrary,
                () => mapa_tatico.MapaTaticoScreen(),
              );
            }
            return _defer(
              mapa_tatico_ponto.loadLibrary,
              () => mapa_tatico_ponto.DetalhePontoScreen(pointId: pointId),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/edital/:id',
      name: 'editalPublico',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const LandingScreen();
        return _defer(
          edital_consulta.loadLibrary,
          () => edital_consulta.EditalConsultaVisitanteScreen(editalId: id),
        );
      },
    ),
    GoRoute(
      path: '/editais',
      name: 'editaisHub',
      builder: (context, state) => _defer(
        editais_hub.loadLibrary,
        () => editais_hub.EditaisHubScreen(),
      ),
      routes: [
        GoRoute(
          path: ':id',
          name: 'editalDetalhe',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return _defer(
                editais_hub.loadLibrary,
                () => editais_hub.EditaisHubScreen(),
              );
            }
            return _defer(
              edital_detalhe.loadLibrary,
              () => edital_detalhe.EditalDetalheScreen(editalId: id),
            );
          },
          routes: [
            GoRoute(
              path: 'consulta',
              name: 'editalConsultaVisitante',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) {
                  return _defer(
                    editais_hub.loadLibrary,
                    () => editais_hub.EditaisHubScreen(),
                  );
                }
                return _defer(
                  edital_consulta.loadLibrary,
                  () => edital_consulta.EditalConsultaVisitanteScreen(editalId: id),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/consultoria-juridica/:id',
      name: 'consultoriaJuridicaDetalhe',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const DashboardEntryScreen();
        return _defer(
          consultoria_detalhe.loadLibrary,
          () => consultoria_detalhe.ConsultoriaAdvogadoDetalheScreen(advogadoId: id),
        );
      },
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => RouteScopedProviders.admin(
        context,
        _defer(
          admin.loadLibrary,
          () => admin.AdminScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/marketplace',
      name: 'marketplace',
      builder: (context, state) => _defer(
        marketplace.loadLibrary,
        () => marketplace.MarketplaceScreen(),
      ),
    ),
    GoRoute(
      path: '/notificacoes',
      name: 'notificacoes',
      builder: (context, state) => _defer(
        notificacoes.loadLibrary,
        () => notificacoes.NotificacoesScreen(),
      ),
    ),
    GoRoute(
      path: '/meus-dados',
      name: 'meusDados',
      builder: (context, state) => _defer(
        profile.loadLibrary,
        () => profile.ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/verificacao/documento',
      name: 'verificacaoDocumento',
      builder: (context, state) => _defer(
        verificacao_doc.loadLibrary,
        () => verificacao_doc.VerificacaoDocumentoScreen(),
      ),
    ),
    GoRoute(
      path: '/verificacao/barreira',
      name: 'verificacaoBarreira',
      builder: (context, state) {
        final titulo = state.uri.queryParameters['titulo'] ?? 'Verificação necessária';
        final descricao = state.uri.queryParameters['descricao'] ??
            'Este recurso exige que sua conta de agente seja verificada.';
        final contextoWhatsapp = state.uri.queryParameters['contexto'];
        return _defer(
          verificacao_barrier.loadLibrary,
          () => verificacao_barrier.VerificacaoBarrierScreen(
            titulo: titulo,
            descricao: descricao,
            contextoWhatsapp: contextoWhatsapp,
          ),
        );
      },
    ),
    GoRoute(
      path: '/permutas',
      name: 'permutas',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final initialTabIndex = tab == 'interessados' ? 3 : 0;
        return _defer(
          permutas.loadLibrary,
          () => permutas.PermutasUnificadasScreen(initialTabIndex: initialTabIndex),
        );
      },
    ),
    GoRoute(
      path: '/permutas-inteligentes',
      name: 'permutasInteligentes',
      builder: (context, state) => _defer(
        permutas.loadLibrary,
        () => permutas.PermutasUnificadasScreen(),
      ),
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => RouteScopedProviders.calendar(
        context,
        _defer(
          calendar.loadLibrary,
          () => calendar.CalendarScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/questions',
      name: 'questions',
      builder: (context, state) => _defer(
        questions_list.loadLibrary,
        () => questions_list.QuestionsListScreen(),
      ),
    ),
    GoRoute(
      path: '/questions/detail/:questionId',
      name: 'questionDetail',
      builder: (context, state) {
        final questionId = int.tryParse(state.pathParameters['questionId'] ?? '');
        if (questionId == null) {
          return _defer(
            questions_list.loadLibrary,
            () => questions_list.QuestionsListScreen(),
          );
        }
        return _defer(
          question_detail.loadLibrary,
          () => question_detail.QuestionDetailScreen(questionId: questionId),
        );
      },
    ),
    GoRoute(
      path: '/questions/comments/:questionId',
      name: 'questionComments',
      builder: (context, state) {
        final questionId = int.tryParse(state.pathParameters['questionId'] ?? '');
        if (questionId == null) {
          return _defer(
            questions_list.loadLibrary,
            () => questions_list.QuestionsListScreen(),
          );
        }
        return _defer(
          question_comments.loadLibrary,
          () => question_comments.QuestionCommentsScreen(questionId: questionId),
        );
      },
    ),
    GoRoute(
      path: '/simulado/create',
      name: 'simuladoCreate',
      builder: (context, state) => _defer(
        simulado_create.loadLibrary,
        () => simulado_create.SimuladoCreateScreen(),
      ),
    ),
    GoRoute(
      path: '/simulado/play/:simuladoId',
      name: 'simuladoPlay',
      builder: (context, state) {
        final simuladoId = int.tryParse(state.pathParameters['simuladoId'] ?? '');
        if (simuladoId == null) {
          return _defer(
            questions_list.loadLibrary,
            () => questions_list.QuestionsListScreen(),
          );
        }
        return _defer(
          simulado_play.loadLibrary,
          () => simulado_play.SimuladoPlayScreen(simuladoId: simuladoId),
        );
      },
    ),
    GoRoute(
      path: '/simulado/result/:simuladoId',
      name: 'simuladoResult',
      builder: (context, state) {
        final simuladoId = int.tryParse(state.pathParameters['simuladoId'] ?? '');
        if (simuladoId == null) {
          return _defer(
            questions_list.loadLibrary,
            () => questions_list.QuestionsListScreen(),
          );
        }
        return _defer(
          simulado_result.loadLibrary,
          () => simulado_result.SimuladoResultScreen(simuladoId: simuladoId),
        );
      },
    ),
    GoRoute(
      path: '/practice',
      name: 'practice',
      builder: (context, state) => _defer(
        practice.loadLibrary,
        () => practice.PracticeScreen(),
      ),
    ),
    GoRoute(
      path: '/practice/history',
      name: 'practiceHistory',
      builder: (context, state) => _defer(
        practice_history.loadLibrary,
        () => practice_history.PracticeHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/questions/admin',
      name: 'questionsAdmin',
      builder: (context, state) => _defer(
        questions_admin.loadLibrary,
        () => questions_admin.QuestionsAdminScreen(),
      ),
    ),
    GoRoute(
      path: '/questions/list-all',
      name: 'questionsListAll',
      builder: (context, state) => _defer(
        questions_list_all.loadLibrary,
        () => questions_list_all.QuestionsListAllScreen(),
      ),
    ),
    GoRoute(
      path: '/chat/conversa/:conversaId',
      name: 'chatConversa',
      builder: (context, state) {
        final conversaId = int.tryParse(state.pathParameters['conversaId'] ?? '');
        final outroUsuarioNome = state.uri.queryParameters['nome'] ?? 'Usuário';
        if (conversaId == null) {
          return const Scaffold(body: Center(child: Text('Conversa não encontrada')));
        }
        return _defer(
          chat_conversa.loadLibrary,
          () => chat_conversa.ChatConversaScreen(
            conversaId: conversaId,
            outroUsuarioNome: outroUsuarioNome,
          ),
        );
      },
    ),
    GoRoute(
      path: '/forum',
      name: 'forum',
      builder: (context, state) => _defer(
        forum_list.loadLibrary,
        () => forum_list.ForumListScreen(),
      ),
    ),
    GoRoute(
      path: '/forum/topico/:topicoId',
      name: 'forumTopico',
      builder: (context, state) {
        final topicoId = int.tryParse(state.pathParameters['topicoId'] ?? '');
        if (topicoId == null) {
          return const Scaffold(body: Center(child: Text('Tópico não encontrado')));
        }
        return _defer(
          forum_topico.loadLibrary,
          () => forum_topico.ForumTopicoScreen(topicoId: topicoId),
        );
      },
    ),
    GoRoute(
      path: '/forum/moderacao',
      name: 'forumModeracao',
      builder: (context, state) => _defer(
        forum_moderacao.loadLibrary,
        () => forum_moderacao.ForumModeracaoScreen(),
      ),
    ),
    GoRoute(
      path: '/premium/success',
      name: 'premiumSuccess',
      builder: (context, state) => _defer(
        premium_success.loadLibrary,
        () => premium_success.PremiumSuccessScreen(),
      ),
    ),
    GoRoute(
      path: '/forum/create-topico',
      name: 'forumCreateTopico',
      builder: (context, state) => _defer(
        forum_create.loadLibrary,
        () => forum_create.ForumCreateTopicoScreen(),
      ),
    ),
  ],
);

/// Classe com constantes de rotas para facilitar navegação
class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String auth = '/auth';
  static const String register = '/auth/register';
  static const String confirmEmail = '/auth/confirm-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String dashboard = '/dashboard';
  static const String completarPerfil = '/completar-perfil';
  static const String mapa = '/mapa';
  static const String mapaVisitante = '/mapa/visitante';
  static const String mapaTatico = '/mapa-tatico';
  static const String authCallback = '/auth/callback';
  static const String editaisHub = '/editais';
  static const String referral = '/referral';
  static String referralLanding(String code) => '/r/$code';

  /// Landing pública de um edital (sem login) — usada em divulgação externa.
  static String editalPublico(int editalId) => '/edital/$editalId';

  static const String forum = '/forum';
  static const String admin = '/admin';
  static const String marketplace = '/marketplace';
  static const String notificacoes = '/notificacoes';
  static const String meusDados = '/meus-dados';
  static const String verificacaoDocumento = '/verificacao/documento';
  static const String verificacaoBarreira = '/verificacao/barreira';
  static const String permutas = '/permutas';
  static const String permutasInteligentes = '/permutas-inteligentes';
  static const String consultoriaJuridica = '/consultoria-juridica';
  static const String calendar = '/calendar';
  static const String questions = '/questions';
  static const String questionDetail = '/questions/detail';
  static const String questionComments = '/questions/comments';
  static const String simuladoCreate = '/simulado/create';
  static const String simuladoPlay = '/simulado/play';
  static const String simuladoResult = '/simulado/result';
  static const String practice = '/practice';
  static const String practiceHistory = '/practice/history';
  static const String questionsAdmin = '/questions/admin';
  static const String questionsListAll = '/questions/list-all';
  static const String premiumSuccess = '/premium/success';
}
