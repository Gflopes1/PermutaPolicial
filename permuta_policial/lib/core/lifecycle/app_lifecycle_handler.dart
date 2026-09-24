import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../services/web_update_checker.dart';
import 'web_resume_bridge.dart';

/// Trata retorno do app após background (web e mobile).
/// Evita tela preta por canvas congelado, sessão/socket stale e chunks deferred presos.
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  Timer? _resumeDebounce;
  bool _handlingResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      registerWebResumeListener(_scheduleResumeHandling);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markFlutterAppReady();
    });
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleResumeHandling();
    }
  }

  void _scheduleResumeHandling() {
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 900), _handleAppResume);
  }

  Future<void> _handleAppResume() async {
    if (!mounted || _handlingResume) return;
    _handlingResume = true;

    try {
      _forceRepaint();

      final auth = context.read<AuthProvider>();
      final socket = context.read<SocketService>();

      await auth.handleAppResume();
      await socket.reconnectIfNeeded();

      if (kIsWeb) {
        triggerWebUpdateCheck();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e, st) {
      debugPrint('⚠️ AppLifecycleHandler resume: $e\n$st');
    } finally {
      _handlingResume = false;
    }
  }

  void _forceRepaint() {
    final binding = WidgetsBinding.instance;
    binding.scheduleFrame();
    binding.ensureVisualUpdate();
    SchedulerBinding.instance.scheduleWarmUpFrame();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Placeholder exibido enquanto o router ainda não montou o child (evita tela vazia).
class AppBootPlaceholder extends StatelessWidget {
  const AppBootPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
