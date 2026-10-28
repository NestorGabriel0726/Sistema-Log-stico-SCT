import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persistError = ref.watch(localStoreProvider.select((s) => s.lastPersistError));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.brand.withValues(alpha: 0.08)
                : AppColors.brandSubtle,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.brand.withValues(alpha: 0.15)
                    : AppColors.brand.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.offline_bolt_rounded,
                size: 14,
                color: isDark ? AppColors.brandLight : AppColors.brand,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Modo local — dados neste dispositivo (sem sincronização com nuvem)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.brandLight : AppColors.brandDark,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (persistError != null)
          Container(
            color: isDark
                ? AppColors.dangerBgDark
                : AppColors.dangerBg,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.save_outlined, color: AppColors.danger, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    persistError,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dispensar',
                  icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => ref.read(localStoreProvider).clearPersistError(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
