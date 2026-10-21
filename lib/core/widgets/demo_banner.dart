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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.08),
            border: Border(bottom: BorderSide(color: AppColors.brand.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.brand),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Modo local — dados neste aparelho (sem nuvem). O Supabase fica para depois.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (persistError != null)
          Material(
            color: AppColors.danger.withValues(alpha: 0.1),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.save_outlined, color: AppColors.danger),
              title: Text(
                persistError,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              trailing: IconButton(
                tooltip: 'Dispensar',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref.read(localStoreProvider).clearPersistError(),
              ),
            ),
          ),
      ],
    );
  }
}
