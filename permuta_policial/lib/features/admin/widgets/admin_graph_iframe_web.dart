import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class AdminGraphIframe extends StatefulWidget {
  const AdminGraphIframe({super.key, required this.url});

  final String url;

  @override
  State<AdminGraphIframe> createState() => _AdminGraphIframeState();
}

class _AdminGraphIframeState extends State<AdminGraphIframe> {
  static int _nextId = 0;
  late final String _viewType;
  late final web.HTMLIFrameElement _iframe;

  @override
  void initState() {
    super.initState();
    _viewType = 'admin-graph-iframe-${_nextId++}';
    _iframe = web.HTMLIFrameElement()
      ..src = widget.url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );
  }

  @override
  void didUpdateWidget(covariant AdminGraphIframe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _iframe.src = widget.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
