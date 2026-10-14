import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../domain/models.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? foreground;

  const TagChip({super.key, required this.label, this.color, this.foreground});

  factory TagChip.finance(FinancialStatus status) {
    return switch (status) {
      FinancialStatus.paid => TagChip(
          label: status.label,
          color: AppColors.success.withValues(alpha: 0.12),
          foreground: AppColors.success,
        ),
      FinancialStatus.partial => TagChip(
          label: status.label,
          color: AppColors.warning.withValues(alpha: 0.15),
          foreground: AppColors.warning,
        ),
      FinancialStatus.unpaid => TagChip(
          label: status.label,
          color: AppColors.danger.withValues(alpha: 0.12),
          foreground: AppColors.danger,
        ),
      FinancialStatus.overpaid => TagChip(
          label: status.label,
          color: AppColors.brand.withValues(alpha: 0.12),
          foreground: AppColors.brand,
        ),
      FinancialStatus.notApplicable => TagChip(label: status.label),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground ?? AppColors.brand,
        ),
      ),
    );
  }
}

class CapacityBar extends StatelessWidget {
  final double ratio;
  final String label;
  final String trailing;

  const CapacityBar({
    super.key,
    required this.ratio,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(trailing, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: ratio >= 1 ? AppColors.danger : AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showStoreMessage(BuildContext context, StoreResult result) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
}

Future<bool> confirmDialog(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ),
  );
  return ok ?? false;
}
