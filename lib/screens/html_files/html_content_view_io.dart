import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders raw HTML directly via a native WebView (mobile platforms).
class HtmlContentView extends StatefulWidget {
  final String htmlContent;
  const HtmlContentView({super.key, required this.htmlContent});

  @override
  State<HtmlContentView> createState() => _HtmlContentViewState();
}

class _HtmlContentViewState extends State<HtmlContentView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
