// lib/core/widgets/aurora_hero.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Per-screen gradient header strip.
///
/// Place at the top of each screen's body. Pass the screen's accent color
/// and the header fills with a tinted glass surface + radial glow.
class AuroraHero extends StatelessWidget {
  final Color accent;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AuroraHero({
    super.key,
    required this.accent,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.glassBorderAccent(accent)),
      ),
      child: Stack(
        children: [
          // Radial glow — top-right ambient light
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: AppTextStyles.eyebrow(color: accent.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 3),
                      Text(title, style: AppTextStyles.headlineLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
