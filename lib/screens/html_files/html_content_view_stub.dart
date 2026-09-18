import 'package:flutter/material.dart';

/// Fallback for platforms without a web or WebView implementation.
class HtmlContentView extends StatelessWidget {
  final String htmlContent;
  const HtmlContentView({super.key, required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('HTML preview is not supported on this platform.'),
    );
  }
}
