import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
class OverviewTab extends ConsumerWidget {
  final String eventId;
  final bool showFinance;
  const OverviewTab({super.key, required this.eventId, required this.showFinance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final event = store.eventById(eventId)!;
    final finance = store.financeSummary(eventId);
    final byMethod = store.financeSummaryByMethod(eventId);
    final perDay = store.passengersPerDay(eventId);
    final stats = store.vehicleDayStats(eventId);
    final activity = store.activityForEvent(eventId).take(8).toList();
    final maxDay = perDay.fold<int>(1, (m, d) => d.passengers > m ? d.passengers : m);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Prazos
        if (event.passageDeadline != null ||
            event.preliminaryListDeadline != null ||
            event.finalListDeadline != null) ...[
          _DeadlineStrip(event: event),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Indicadores financeiros
        if (showFinance) ...[
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Esperado',
                  value: AppFormatters.cents(finance.expectedCents),
                  accentColor: AppColors.brand,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetricCard(
                  label: 'Recebido',
                  value: AppFormatters.cents(finance.paidCents),
                  accentColor: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetricCard(
                  label: 'Pendente',
                  value: AppFormatters.cents(finance.pendingCents),
                  accentColor: finance.pendingCents > 0
                      ? AppColors.danger
                      : AppColors.success,
                  icon: finance.pendingCents > 0
                      ? Icons.error_outline_rounded
                      : Icons.done_all_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Detalhamento por método de pagamento
          _FinanceByMethodCard(byMethod: byMethod, isDark: isDark, theme: theme, cs: cs),
        ] else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Resumo financeiro restrito à coordenação.',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.xl),

        // Passageiros por dia
        SectionHeader(
          title: 'Passageiros por dia',
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        if (perDay.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Nenhum dia cadastrado.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: perDay
                  .map(
                    (d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(
                              '${d.passengers}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 12 + (64 * (d.passengers / maxDay)),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d.label.split('-').first,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Lotação dos veículos
        if (stats.isNotEmpty) ...[
          SectionHeader(
            title: 'Lotação dos veículos',
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: stats
                  .map(
                    (s) => CapacityBar(
                      ratio: s.ratio,
                      label: '${s.vehicleName} · ${s.dayLabel}',
                      trailing: '${s.occupied}/${s.capacity}',
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Atividade recente
        SectionHeader(
          title: 'Atividade recente',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        if (activity.isEmpty)
          Text(
            'Nenhuma atividade registrada.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          Material(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: activity.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (context, i) {
                final a = activity[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                    child: Text(
                      a.actorName.isNotEmpty ? a.actorName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand),
                    ),
                  ),
                  title: Text(a.message, style: theme.textTheme.bodySmall),
                  subtitle: Text(
                    '${a.actorName} · ${AppFormatters.date(a.at)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _DeadlineStrip extends StatelessWidget {
  final TransportEvent event;
  const _DeadlineStrip({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = [
      ('Passagens', event.passageDeadline),
      ('Lista prévia', event.preliminaryListDeadline),
      ('Lista definitiva', event.finalListDeadline),
    ].where((e) => e.$2 != null);

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((e) {
        final late = now.isAfter(e.$2!);
        return StatusChip(
          label: '${e.$1}: ${AppFormatters.date(e.$2!)}',
          background: late ? AppColors.dangerBg : AppColors.infoBg,
          foreground: late ? AppColors.danger : AppColors.info,
          icon: late ? Icons.warning_amber_rounded : Icons.event_outlined,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de resumo financeiro por método de pagamento
// ─────────────────────────────────────────────────────────────────────────────

class _FinanceByMethodCard extends StatelessWidget {
  final FinanceSummaryByMethod byMethod;
  final bool isDark;
  final ThemeData theme;
  final ColorScheme cs;

  const _FinanceByMethodCard({
    required this.byMethod,
    required this.isDark,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (byMethod.totalCents == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 16, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Recebimentos por método',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (byMethod.pixCents > 0)
            _MethodRow(
              icon: Icons.qr_code_rounded,
              label: 'PIX',
              amount: byMethod.pixCents,
              color: AppColors.brand,
              theme: theme,
              cs: cs,
              isDark: isDark,
            ),
          if (byMethod.cashCents > 0)
            _MethodRow(
              icon: Icons.payments_outlined,
              label: 'Espécie',
              amount: byMethod.cashCents,
              color: AppColors.success,
              theme: theme,
              cs: cs,
              isDark: isDark,
            ),
          if (byMethod.unknownCents > 0)
            _MethodRow(
              icon: Icons.help_outline_rounded,
              label: 'Sem método',
              amount: byMethod.unknownCents,
              color: cs.onSurfaceVariant,
              theme: theme,
              cs: cs,
              isDark: isDark,
              subtitle: 'Registros anteriores sem rastreamento por método',
            ),
          if (byMethod.hasMultipleMethods) ...[
            Divider(
              height: AppSpacing.md,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total recebido',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  AppFormatters.cents(byMethod.totalCents),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;
  final ThemeData theme;
  final ColorScheme cs;
  final bool isDark;
  final String? subtitle;

  const _MethodRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.theme,
    required this.cs,
    required this.isDark,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            AppFormatters.cents(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veículos
// ─────────────────────────────────────────────────────────────────────────────

