import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import 'admin_graph_iframe_stub.dart'
    if (dart.library.html) 'admin_graph_iframe_web.dart';
import 'admin_graph_token_storage_stub.dart'
    if (dart.library.html) 'admin_graph_token_storage_web.dart';

enum AdminGraphView { poster, interactive }

const _graphPosterPath = '/api/grafo-permutas-poster.html';
const _graphInteractivePath = '/api/graph-viewer.html';

class AdminGraphTab extends StatefulWidget {
  const AdminGraphTab({super.key});

  @override
  State<AdminGraphTab> createState() => _AdminGraphTabState();
}

class _AdminGraphTabState extends State<AdminGraphTab>
    with AutomaticKeepAliveClientMixin {
  AdminGraphView _view = AdminGraphView.poster;
  WebViewController? _controller;
  String? _webGraphUrl;
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  String get _graphPath => switch (_view) {
        AdminGraphView.poster => _graphPosterPath,
        AdminGraphView.interactive => _graphInteractivePath,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWebView());
  }

  Future<void> _initWebView() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _controller = null;
      _webGraphUrl = null;
    });

    final token = await context.read<StorageService>().getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Sessão expirada, faça login novamente';
      });
      return;
    }

    final graphUrl = Uri.parse('${AppConfig.apiBaseUrl}$_graphPath').replace(
      queryParameters: {'token': token},
    );

    if (kIsWeb) {
      setAdminGraphToken(token);
      if (!mounted) return;
      setState(() {
        _webGraphUrl = graphUrl.toString();
        _isLoading = false;
      });
      return;
    }

    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            await controller.runJavaScript(
              "localStorage.setItem('admin_token', ${jsonEncode(token)});",
            );
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = 'Erro ao carregar: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(graphUrl);

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _switchView(AdminGraphView view) {
    if (_view == view) return;
    setState(() => _view = view);
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SegmentedButton<AdminGraphView>(
            segments: const [
              ButtonSegment(
                value: AdminGraphView.poster,
                icon: Icon(Icons.map_outlined, size: 18),
                label: Text('Pôster'),
              ),
              ButtonSegment(
                value: AdminGraphView.interactive,
                icon: Icon(Icons.hub_outlined, size: 18),
                label: Text('Grafo interativo'),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              _switchView(selection.first);
            },
          ),
        ),
        Expanded(child: _buildGraphBody()),
      ],
    );
  }

  Widget _buildGraphBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initWebView,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final webGraphUrl = _webGraphUrl;
    if (kIsWeb && webGraphUrl != null) {
      return AdminGraphIframe(
        key: ValueKey(webGraphUrl),
        url: webGraphUrl,
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
