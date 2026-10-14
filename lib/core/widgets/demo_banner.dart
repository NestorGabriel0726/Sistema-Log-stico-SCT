import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
