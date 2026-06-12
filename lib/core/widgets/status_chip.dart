// lib/core/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Colored label chip for task/item status.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  const StatusChip.done({super.key})
      : label = 'Done', color = AppColors.statusDone;

  const StatusChip.pending({super.key})
      : label = 'Pending', color = AppColors.statusPending;

  const StatusChip.overdue({super.key})
      : label = 'Overdue', color = AppColors.statusOverdue;

  factory StatusChip.custom({Key? key, required String label, required Color accent}) =>
      StatusChip(key: key, label: label, color: accent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
