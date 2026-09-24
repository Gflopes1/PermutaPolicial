import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permuta_policial/core/services/push_notification_service.dart';
import 'package:permuta_policial/core/utils/pwa_utils.dart';
import 'package:permuta_policial/core/utils/web_notification_utils.dart';
import 'package:permuta_policial/features/auth/providers/auth_provider.dart';
import 'package:permuta_policial/features/auth/providers/auth_status.dart';
import 'package:permuta_policial/shared/widgets/web_push_denied_help.dart';

const _kDismissedAtKey = 'web_push_prompt_dismissed_at_ms';
const _kPendingDismissedAtKey = 'web_push_pending_dismissed_at_ms';
const _kDismissCooldownDays = 7;

/// Overlay de push — deve ser usado apenas dentro de `MaterialApp.builder`,
/// nunca envolvendo o [MaterialApp] (setState recriaria o app inteiro).
class WebPushPermissionOverlay extends StatefulWidget {
  const WebPushPermissionOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<WebPushPermissionOverlay> createState() =>
      _WebPushPermissionOverlayState();
}

class _WebPushPermissionOverlayState extends State<WebPushPermissionOverlay> {
  bool _visible = false;
  bool _loading = false;
  String? _configWarning;
  bool _evaluating = false;
  /// Permissão já concedida, mas token FCM ainda não — exige clique (Android Chrome).
  bool _pendingTokenOnly = false;
  bool _setupComplete = false;

  bool _isWithinDismissCooldown(int? dismissedAtMs) {
    if (dismissedAtMs == null) return false;
    final dismissed = DateTime.fromMillisecondsSinceEpoch(dismissedAtMs);
    return DateTime.now().difference(dismissed).inDays < _kDismissCooldownDays;
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      context.read<AuthProvider>().addListener(_onAuthChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateVisibility();
      });
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    }
    super.dispose();
  }

  void _onAuthChanged() {
    if (_setupComplete || _visible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateVisibility());
  }

  Future<bool> _shouldHideBanner(PushNotificationService push) async {
    if (await push.isWebPushSetupComplete()) return true;
    if (push.currentToken != null) return true;
    return false;
  }

  Future<void> _evaluateVisibility() async {
    if (!kIsWeb || !mounted || _evaluating) return;
    _evaluating = true;

    try {
      final auth = context.read<AuthProvider>();
      if (auth.status != AuthStatus.authenticated) {
        if (_visible && mounted) {
          setState(() {
            _visible = false;
            _configWarning = null;
          });
        }
        return;
      }

      final push = context.read<PushNotificationService>();
      if (!push.isInitialized) {
        await push.initialize();
      }

      if (!push.isConfigured) {
        final issue = push.webConfigIssue;
        debugPrint('⚠️ Web push banner: $issue');
        if (mounted) {
          setState(() {
            _configWarning = issue;
            _visible = issue != null;
          });
        }
        return;
      }

      _configWarning = null;

      final permission = getWebNotificationPermission();
      if (permission == 'unsupported') {
        debugPrint(
          '⚠️ Web push: Notification API unsupported (iOS Safari sem PWA?)',
        );
        if (_visible && mounted) setState(() => _visible = false);
        return;
      }

      if (permission == 'denied') {
        if (_visible && mounted) {
          setState(() {
            _visible = false;
            _pendingTokenOnly = false;
          });
        }
        return;
      }

      if (await _shouldHideBanner(push)) {
        _setupComplete = true;
        if (_visible && mounted) {
          setState(() {
            _visible = false;
            _pendingTokenOnly = false;
          });
        }
        return;
      }

      if (permission != 'default') {
        if (permission == 'granted') {
          final prefs = await SharedPreferences.getInstance();
          if (_isWithinDismissCooldown(prefs.getInt(_kPendingDismissedAtKey))) {
            if (_visible && mounted) {
              setState(() {
                _visible = false;
                _pendingTokenOnly = false;
              });
            }
            return;
          }
          debugPrint(
            'ℹ️ Web push: permissão granted, token pendente — aguardando clique em "Ativar"',
          );
          if (mounted) {
            setState(() {
              _visible = true;
              _pendingTokenOnly = true;
            });
          }
          return;
        }
        if (_visible && mounted) {
          setState(() {
            _visible = false;
            _pendingTokenOnly = false;
          });
        }
        return;
      }

      _pendingTokenOnly = false;

      final prefs = await SharedPreferences.getInstance();
      if (_isWithinDismissCooldown(prefs.getInt(_kDismissedAtKey))) {
        debugPrint('ℹ️ Web push: banner oculto (cooldown 7 dias após "Agora não")');
        return;
      }

      if (mounted) {
        setState(() {
          _visible = true;
          _pendingTokenOnly = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Web push banner: erro ao avaliar visibilidade — $e');
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _onEnable() async {
    setState(() => _loading = true);
    final push = context.read<PushNotificationService>();
    final permissionBefore = getWebNotificationPermission();
    final ok = await push.requestWebPermissionAndRegister();
    if (!mounted) return;
    setState(() {
      _loading = false;
      final permissionAfter = getWebNotificationPermission();
      if (ok) {
        _setupComplete = true;
        _visible = false;
        _configWarning = null;
        _pendingTokenOnly = false;
      } else if (permissionAfter == 'granted') {
        _visible = true;
        _configWarning = null;
        _pendingTokenOnly = true;
      } else {
        _visible = push.shouldPromptWebPermission;
        _pendingTokenOnly = false;
      }
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificações ativadas com sucesso.')),
      );
    } else {
      final after = getWebNotificationPermission();
      if (after == 'granted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissão aceita. Recarregue a página (F5) para concluir o registro do push.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      } else if (after == 'denied' || permissionBefore == 'denied') {
        await showWebPushDeniedHelpDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível ativar. Verifique se o popup do navegador não foi bloqueado.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pendingTokenOnly ? _kPendingDismissedAtKey : _kDismissedAtKey;
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Sem Material elevation: no Flutter web o shadow/elevation pode pintar
    // um scrim cinza em toda a tela ao mover o mouse fora do card.
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
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
                              Icon(
                                _configWarning != null
                                    ? Icons.warning_amber_outlined
                                    : Icons.notifications_active_outlined,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _configWarning != null
                                      ? 'Push não configurado'
                                      : (_pendingTokenOnly
                                          ? 'Concluir ativação dos alertas'
                                          : (isPWA()
                                              ? 'Ativar alertas no app'
                                              : 'Ativar alertas no navegador')),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_configWarning == null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _loading ? null : _onDismiss,
                                  tooltip: 'Agora não',
                                  style: IconButton.styleFrom(
                                    foregroundColor: scheme.onSurface,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _configWarning ??
                                (_pendingTokenOnly
                                    ? 'A permissão já foi concedida. Toque abaixo para finalizar o registro neste dispositivo.'
                                    : (isPWA()
                                        ? 'Receba avisos de matches, mensagens e mapa tático mesmo com o app fechado.'
                                        : webPushBannerHint())),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface,
                                ),
                          ),
                          if (_configWarning == null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _loading ? null : _onDismiss,
                                  child: const Text('Agora não'),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: _loading ? null : _onEnable,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_pendingTokenOnly
                                          ? 'Concluir ativação'
                                          : 'Ativar notificações'),
                                ),
                              ],
                            ),
                          ],
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

/// @deprecated Use [WebPushPermissionOverlay] dentro de MaterialApp.builder.
typedef WebPushPermissionBanner = WebPushPermissionOverlay;
