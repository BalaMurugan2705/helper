// lib/core/widgets/glass_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shows a bottom sheet on mobile (< 800px width) and a centered dialog
/// on desktop/tablet (>= 800px).
///
/// Pass [title] and [content]. The container adapts automatically.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  bool isDismissible = true,
}) {
  final isWide = MediaQuery.of(context).size.width >= 800;
  if (isWide) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (_) => _GlassDialog(title: title, content: content),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GlassSheet(title: title, content: content),
  );
}

class _GlassSheet extends StatelessWidget {
  final String title;
  final Widget content;
  const _GlassSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.textSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  const _GlassDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
