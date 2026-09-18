import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../models/html_file.dart';
import 'html_content_view.dart';

class HtmlFileViewerScreen extends StatelessWidget {
  final HtmlFile file;
  const HtmlFileViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentHtmlFiles,
            eyebrow: 'HTML FILE',
            title: file.name,
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.accentHtmlFiles,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/html-files'),
            ),
          ),
          Expanded(child: HtmlContentView(htmlContent: file.content)),
        ],
      ),
    );
  }
}
