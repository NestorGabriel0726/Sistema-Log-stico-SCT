import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
class HistoryTab extends ConsumerWidget {
  final String eventId;
  const HistoryTab({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(localStoreProvider).activityForEvent(eventId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.history_outlined,
        title: 'Sem histórico ainda',
        subtitle: 'As ações da equipe aparecerão aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        indent: 48,
      ),
      itemBuilder: (context, i) {
        final a = items[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.brand.withValues(alpha: 0.1),
            child: Text(
              a.actorName.isNotEmpty ? a.actorName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
          title: Text(a.message, style: theme.textTheme.bodySmall),
          subtitle: Text(
            '${a.actorName} · ${AppFormatters.date(a.at)}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontSize: 11),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Configurações
// ─────────────────────────────────────────────────────────────────────────────

