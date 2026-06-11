// lib/core/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Frosted-glass surface container.
///
/// For blur effects, wrap with a [BackdropFilter] at the call site only where
/// the background is sufficiently complex and frame budget allows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final border = accent != null
        ? AppColors.glassBorderAccent(accent!)
        : AppColors.glassBorder;
    final bg = accent != null
        ? AppColors.glassCardAccent(accent!)
        : AppColors.glassCard;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: border),
          boxShadow: accent != null
              ? [BoxShadow(color: accent!.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))]
              : null,
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
