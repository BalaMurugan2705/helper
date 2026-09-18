import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Renders raw HTML directly in the browser via a sandboxed iframe.
///
/// Scripts are allowed (so interactive files render correctly) but
/// `allow-same-origin` is deliberately omitted, so the iframe content runs
/// in an opaque origin with no access to this app's storage or cookies.
class HtmlContentView extends StatefulWidget {
  final String htmlContent;
  const HtmlContentView({super.key, required this.htmlContent});

  @override
  State<HtmlContentView> createState() => _HtmlContentViewState();
}

class _HtmlContentViewState extends State<HtmlContentView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'html-file-view-${identityHashCode(widget)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('sandbox', 'allow-scripts')
        ..srcdoc = widget.htmlContent.toJS;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
