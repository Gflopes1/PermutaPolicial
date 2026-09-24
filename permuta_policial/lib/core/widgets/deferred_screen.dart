import 'dart:async';

import 'package:flutter/material.dart';

/// Carrega um módulo `deferred` antes de montar a tela — reduz o bundle inicial web.
class DeferredScreen extends StatefulWidget {
  const DeferredScreen({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.loadingWidget,
    this.timeout = const Duration(seconds: 30),
  });

  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? loadingWidget;
  final Duration timeout;

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  bool _loaded = false;
  bool _failed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _loaded = false;
    });

    _attempt += 1;
    final attempt = _attempt;

    try {
      await widget.loadLibrary().timeout(
        widget.timeout,
        onTimeout: () => throw TimeoutException(
          'Carregamento excedeu ${widget.timeout.inSeconds}s',
        ),
      );
    } catch (e) {
      debugPrint('⚠️ DeferredScreen loadLibrary (tentativa $attempt): $e');
      if (!mounted || attempt != _attempt) return;
      setState(() => _failed = true);
      return;
    }

    if (!mounted || attempt != _attempt) return;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível carregar esta tela.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_loaded) {
      return widget.loadingWidget ?? const _DefaultDeferredLoading();
    }

    return widget.builder();
  }
}

class _DefaultDeferredLoading extends StatelessWidget {
  const _DefaultDeferredLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}
