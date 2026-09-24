import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:permuta_policial/core/services/web_update_checker.dart';

/// Banner persistente quando há nova build no servidor (Flutter web).
class WebUpdateOverlay extends StatefulWidget {
  const WebUpdateOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<WebUpdateOverlay> createState() => _WebUpdateOverlayState();
}

class _WebUpdateOverlayState extends State<WebUpdateOverlay> {
  bool _visible = false;
  bool _updating = false;
  String? _remoteBuildId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerWebUpdateListener(_onUpdateAvailable);
      registerWebUpdateClearedListener(_onUpdateCleared);
    }
  }

  void _onUpdateCleared() {
    if (!mounted) return;
    setState(() {
      _visible = false;
      _updating = false;
      _remoteBuildId = null;
    });
  }

  void _onUpdateAvailable(String buildId) {
    if (!mounted || _updating) return;
    setState(() {
      _visible = true;
      _remoteBuildId = buildId;
    });
  }

  Future<void> _onUpdateNow() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await applyWebUpdate();
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  void _onDismiss() {
    if (_updating) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.system_update_alt, color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Nova versão disponível',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _updating ? null : _onDismiss,
                                tooltip: 'Depois',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uma atualização do Permuta Policial foi publicada. '
                            'Atualize agora para evitar erros por cache antigo.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_remoteBuildId != null && kDebugMode) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Build: $_remoteBuildId',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _updating ? null : _onDismiss,
                                child: const Text('Depois'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: _updating ? null : _onUpdateNow,
                                child: _updating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Atualizar agora'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
