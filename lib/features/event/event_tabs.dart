import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/utils/domain_calculations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/local_app_store.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';
import 'passage_form_page.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Visão Geral
// ─────────────────────────────────────────────────────────────────────────────

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

class VehiclesTab extends ConsumerStatefulWidget {
  final String eventId;
  const VehiclesTab({super.key, required this.eventId});

  @override
  ConsumerState<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends ConsumerState<VehiclesTab> {
  String? _dayId;

  void _showStopsDialog(BuildContext context, WidgetRef ref, Vehicle vehicle, String? dayId) {
    final store = ref.read(localStoreProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${vehicle.name} — Pontos de Parada'),
          content: SizedBox(
            width: 500,
            child: vehicle.stops.isEmpty
                ? const Text('Nenhum ponto de parada cadastrado.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: vehicle.stops.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, idx) {
                      final s = vehicle.stops[idx];
                      final paxs = store
                          .allocationsForStop(vehicle.id, s.id)
                          .where((a) => dayId == null || a.dayId == dayId)
                          .map((a) => store.passengerById(a.passengerId)?.name ?? '')
                          .where((name) => name.isNotEmpty)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                child: Text('${s.sequence}', style: const TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Text('${paxs.length} passageiro(s)', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (s.reference != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 32, top: 2),
                              child: Text(s.reference!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          if (paxs.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 32, top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: paxs
                                    .map((name) => Chip(
                                          label: Text(name, style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final days = store.daysForEvent(widget.eventId);
    _dayId ??= days.isEmpty ? null : days.first.id;
    final vehicles = store.vehiclesForEvent(widget.eventId);
    final user = store.user!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'Nenhum veículo cadastrado',
        subtitle: 'Adicione ônibus ou carros conforme a demanda das passagens.',
        action: user.canEditOperations
            ? FilledButton.icon(
                onPressed: () => showVehicleSheet(context, ref, widget.eventId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar veículo'),
              )
            : null,
      );
    }

    return Column(
      children: [
        // Seletor de dia
        if (days.isNotEmpty)
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: days.map((d) {
                      final selected = _dayId == d.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(d.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _dayId = d.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ],
            ),
          ),

        // Lista de veículos
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final v = vehicles[i];
              final dayId = _dayId;
              final rows = dayId == null
                  ? <Allocation>[]
                  : store.allocationsForVehicleDay(v.id, dayId);
              final active = rows.where((a) => a.isActive).length;
              final ratio = v.localCapacity == 0 ? 0.0 : active / v.localCapacity;
              final isFull = ratio >= 1.0;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isFull
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do veículo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isFull ? AppColors.danger : AppColors.brand)
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Icon(
                              v.type == VehicleType.bus
                                  ? Icons.directions_bus_rounded
                                  : Icons.directions_car_rounded,
                              size: 18,
                              color: isFull ? AppColors.danger : AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: theme.textTheme.titleSmall),
                                Text(
                                  '${v.type.label} · Fís. ${v.physicalCapacity} · Local ${v.localCapacity}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          if (isFull)
                            const Padding(
                              padding: EdgeInsets.only(right: AppSpacing.xs),
                              child: StatusChip(
                                label: 'LOTADO',
                                background: AppColors.dangerBg,
                                foreground: AppColors.danger,
                              ),
                            ),
                          if (v.stops.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.pin_drop_outlined, size: 18),
                              tooltip: 'Ver passageiros por parada',
                              color: AppColors.brand,
                              onPressed: () => _showStopsDialog(context, ref, v, dayId),
                            ),
                          if (user.canEditOperations)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Editar veículo',
                              color: cs.onSurfaceVariant,
                              onPressed: () => showVehicleSheet(
                                  context, ref, widget.eventId,
                                  existing: v),
                            ),
                        ],
                      ),
                    ),

                    // Barra de lotação
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: CapacityBar(
                        ratio: ratio,
                        label: 'Ocupação do dia',
                        trailing: '$active/${v.localCapacity} vagas',
                      ),
                    ),
                    if (v.stops.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                        child: Text(
                          'Itinerário: ${v.stops.map((s) => s.name).join(' → ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Lista de passageiros
                    if (rows.isNotEmpty) ...[
                      Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      ...rows.map((a) =>
                          _AllocationTile(allocation: a, eventId: widget.eventId)),
                    ] else if (dayId != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                        child: Text(
                          'Nenhum passageiro neste dia.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),

                    // Ação de alocar
                    if (user.canEditOperations && dayId != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, AppSpacing.sm),
                        child: TextButton.icon(
                          onPressed: () =>
                              _allocateSheet(context, ref, v, dayId),
                          icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                          label: const Text('Alocar passageiro'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _allocateSheet(
      BuildContext context, WidgetRef ref, Vehicle vehicle, String dayId) async {
    final store = ref.read(localStoreProvider);
    final options = store.unallocatedOnDay(widget.eventId, dayId);
    if (options.isEmpty) {
      if (context.mounted) {
        await showStoreMessage(context,
            const StoreResult.error('Não há passageiros livres neste dia.'));
      }
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Passenger>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person_add_alt_rounded),
            title: Text('Alocar passageiro'),
          ),
          ...options.map(
            (p) => ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(p.name),
              subtitle: Text(p.category.label),
              onTap: () => Navigator.pop(ctx, p),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;

    VehicleStop? chosenStop;
    if (vehicle.stops.isNotEmpty) {
      chosenStop = await showModalBottomSheet<VehicleStop>(
        context: context,
        builder: (ctx) => ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.pin_drop_outlined),
              title: Text('Selecione o ponto de embarque'),
              subtitle: Text('Onde o passageiro irá embarcar neste ônibus'),
            ),
            ...vehicle.stops.map(
              (s) => ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                  child: Text(
                    '${s.sequence}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(s.name),
                subtitle: s.reference != null ? Text(s.reference!) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
      if (chosenStop == null || !context.mounted) return;
    }

    final result = store.allocate(
      passengerId: chosen.id,
      vehicleId: vehicle.id,
      dayId: dayId,
      stopId: chosenStop?.id,
    );
    if (context.mounted) await showStoreMessage(context, result);
  }
}

class _AllocationTile extends ConsumerWidget {
  final Allocation allocation;
  final String eventId;
  const _AllocationTile({required this.allocation, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final p = store.passengerById(allocation.passengerId);
    final stop = allocation.stopId != null
        ? store.stopById(allocation.vehicleId, allocation.stopId!)
        : null;
    final dest = allocation.relocatedToVehicleId == null
        ? null
        : store.vehicleById(allocation.relocatedToVehicleId!);
    final sub = allocation.substitutePassengerId == null
        ? null
        : store.passengerById(allocation.substitutePassengerId!);
    final replaced = allocation.replacedPassengerId == null
        ? null
        : store.passengerById(allocation.replacedPassengerId!);
    final name = p?.name ?? '—';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isDesisted = allocation.status == AllocationStatus.desisted;
    final isRelocated = allocation.status == AllocationStatus.relocated;

    Widget nameWidget;
    Color? dotColor;
    String? statusLabel;

    if (isDesisted && sub != null) {
      dotColor = AppColors.warning;
      statusLabel = 'Substituído por ${sub.name}';
      nameWidget = Text.rich(
        TextSpan(children: [
          TextSpan(
            text: name,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: cs.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: '  →  ${sub.name}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ]),
        style: theme.textTheme.bodyMedium,
      );
    } else if (isDesisted) {
      dotColor = AppColors.danger;
      statusLabel = 'Desistente';
      nameWidget = Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: cs.onSurfaceVariant,
        ),
      );
    } else if (isRelocated) {
      dotColor = AppColors.warning;
      statusLabel = 'Realocado → ${dest?.name ?? 'outro veículo'}';
      nameWidget = Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: cs.onSurfaceVariant,
        ),
      );
    } else if (replaced != null) {
      dotColor = AppColors.info;
      statusLabel = 'Substituto de ${replaced.name}';
      nameWidget = Text(name, style: theme.textTheme.bodyMedium);
    } else {
      nameWidget = Text(name, style: theme.textTheme.bodyMedium);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Número de posição
          SizedBox(
            width: 28,
            child: Text(
              '#${allocation.position}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Indicador de status
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else
            const SizedBox(width: AppSpacing.md),
          // Nome e categoria
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameWidget,
                if (statusLabel != null || p?.category != null || stop != null)
                  Text(
                    [
                      if (p?.category != null) p!.category.label,
                      if (stop != null) 'Parada: ${stop.name}',
                      if (statusLabel != null) statusLabel,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          // Ações
          if (allocation.isActive && store.user?.canEditOperations == true)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'desist') {
                  await _desistFlow(context, ref, allocation);
                } else if (value == 'move') {
                  await _relocateFlow(context, ref, allocation);
                }
              },
              tooltip: 'Ações',
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'desist',
                  child: Row(children: [
                    Icon(Icons.exit_to_app_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Registrar desistência'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'move',
                  child: Row(children: [
                    Icon(Icons.swap_horiz_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Realocar para outro veículo'),
                  ]),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 18),
            ),
        ],
      ),
    );
  }
}

Future<void> _relocateFlow(
    BuildContext context, WidgetRef ref, Allocation allocation) async {
  final store = ref.read(localStoreProvider);
  final passenger = store.passengerById(allocation.passengerId);
  final vehicles = store
      .vehiclesForEvent(passenger!.eventId)
      .where((v) => v.id != allocation.vehicleId);
  final dest = await showModalBottomSheet<Vehicle>(
    context: context,
    builder: (ctx) => ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.swap_horiz_rounded),
          title: Text('Mover para'),
        ),
        ...vehicles.map(
          (v) => ListTile(
            leading: const Icon(Icons.directions_bus_outlined, size: 18),
            title: Text(v.name),
            onTap: () => Navigator.pop(ctx, v),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
  if (dest == null || !context.mounted) return;

  VehicleStop? chosenStop;
  if (dest.stops.isNotEmpty) {
    chosenStop = await showModalBottomSheet<VehicleStop>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.pin_drop_outlined),
            title: Text('Selecione o ponto de embarque no novo veículo'),
          ),
          ...dest.stops.map(
            (s) => ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                child: Text(
                  '${s.sequence}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(s.name),
              subtitle: s.reference != null ? Text(s.reference!) : null,
              onTap: () => Navigator.pop(ctx, s),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (chosenStop == null || !context.mounted) return;
  }

  var result = store.relocate(
    allocationId: allocation.id,
    targetVehicleId: dest.id,
    targetStopId: chosenStop?.id,
  );
  if (result.needsConfirm) {
    final ok = await confirmDialog(context, result.message);
    if (ok) {
      result = store.relocate(
        allocationId: allocation.id,
        targetVehicleId: dest.id,
        targetStopId: chosenStop?.id,
        confirmed: true,
      );
    } else {
      return;
    }
  }
  if (context.mounted) await showStoreMessage(context, result);
}

Future<void> _desistFlow(
    BuildContext context, WidgetRef ref, Allocation allocation) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Registrar desistência'),
      content: const Text(
          'Esta posição terá um substituto ou ficará vaga?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')),
        OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'none'),
            child: const Text('Vaga seca')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, 'sub'),
            child: const Text('Com substituto')),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final store = ref.read(localStoreProvider);
  if (choice == 'none') {
    final result = store.markDesisted(allocationId: allocation.id);
    if (context.mounted) await showStoreMessage(context, result);
    return;
  }
  final name = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Dados do substituto'),
      content: TextField(
        controller: name,
        decoration: const InputDecoration(
          labelText: 'Nome completo',
          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
        ),
        textInputAction: TextInputAction.done,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar')),
      ],
    ),
  );
  if (ok != true || name.text.trim().isEmpty || !context.mounted) return;
  var result = store.markDesisted(
    allocationId: allocation.id,
    substitute: PassengerDraft(name: name.text, dayIds: [allocation.dayId]),
  );
  if (result.needsConfirm) {
    final yes = await confirmDialog(context, result.message);
    if (yes) {
      result = store.markDesisted(
        allocationId: allocation.id,
        substitute: PassengerDraft(name: name.text, dayIds: [allocation.dayId]),
        confirmRelocate: true,
      );
    } else {
      return;
    }
  }
  if (context.mounted) await showStoreMessage(context, result);
}

// ─────────────────────────────────────────────────────────────────────────────
// Passageiros
// ─────────────────────────────────────────────────────────────────────────────

class PassengersTab extends ConsumerStatefulWidget {
  final String eventId;
  const PassengersTab({super.key, required this.eventId});

  @override
  ConsumerState<PassengersTab> createState() => _PassengersTabState();
}

enum _PaxFilter { all, alpha, unpaid, missingDoc, minor, student, exempt }

class _PassengersTabState extends ConsumerState<PassengersTab> {
  _PaxFilter _filter = _PaxFilter.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final event = store.eventById(widget.eventId)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    var list = store.passengersForEvent(widget.eventId);

    // Filtros
    list = switch (_filter) {
      _PaxFilter.all => list,
      _PaxFilter.alpha => [...list]..sort((a, b) => a.name.compareTo(b.name)),
      _PaxFilter.unpaid => list.where((p) {
          final g = store.passageById(p.passageId);
          if (g == null) return false;
          final st = store.financialStatus(g);
          return st == FinancialStatus.unpaid || st == FinancialStatus.partial;
        }).toList(),
      _PaxFilter.missingDoc => list.where((p) => p.missingDocument).toList(),
      _PaxFilter.minor =>
        list.where((p) => p.category == PassengerCategory.minor).toList(),
      _PaxFilter.student =>
        list.where((p) => p.category == PassengerCategory.student).toList(),
      _PaxFilter.exempt => list.where((p) {
          if (p.birthDate != null) {
            return DomainCalculations.isExemptByAge(
              birthDate: p.birthDate!,
              eventDate: event.startDate,
              minimumPayingAge: event.minimumPayingAge,
            );
          }
          return false;
        }).toList(),
    };

    // Busca por nome
    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        // Barra de busca e filtros
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            children: [
              // Busca
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _PaxFilter.values.map((f) {
                    final label = switch (f) {
                      _PaxFilter.all => 'Todos',
                      _PaxFilter.alpha => 'A–Z',
                      _PaxFilter.unpaid => 'Pend. pagamento',
                      _PaxFilter.missingDoc => 'Pend. documento',
                      _PaxFilter.minor => 'Menor',
                      _PaxFilter.student => 'Estudante',
                      _PaxFilter.exempt => 'Isento',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(label),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        // Lista de passageiros
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'Nenhum passageiro encontrado',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    indent: 56,
                  ),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    final passage = store.passageById(p.passageId);
                    final due = store.expectedCentsForPassenger(p, event);
                    final hasDataIssue = p.hasDataPending;
                    FinancialStatus? st;
                    if (passage != null) st = store.financialStatus(passage);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.brand.withValues(alpha: 0.1),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (hasDataIssue)
                            Tooltip(
                              message: 'Pendência de dados',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        [
                          p.category.label,
                          if (passage != null) 'Passagem: ${passage.buyerName}',
                          '${p.dayIds.length} dia(s)',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (st != null) StatusChip.finance(st),
                          if (p.needsAgeReview(event))
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: StatusChip(
                                label: 'Revisão Idade',
                                background: AppColors.warningBg,
                                foreground: AppColors.warning,
                                icon: Icons.warning_amber_rounded,
                              ),
                            ),
                          if (store.user?.canViewFinance == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              due == 0
                                  ? 'Isento'
                                  : AppFormatters.cents(due),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passagens
// ─────────────────────────────────────────────────────────────────────────────

class PassagesTab extends ConsumerStatefulWidget {
  final String eventId;
  const PassagesTab({super.key, required this.eventId});

  @override
  ConsumerState<PassagesTab> createState() => _PassagesTabState();
}

enum _PassFilter { all, finance, data, ok }

class _PassagesTabState extends ConsumerState<PassagesTab> {
  _PassFilter _filter = _PassFilter.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canEdit = store.user?.canEditOperations == true;

    var groups = store.passagesForEvent(widget.eventId).where((g) {
      final pax =
          g.passengerIds.map(store.passengerById).whereType<Passenger>();
      final dataPending = pax.any((p) => p.hasDataPending);
      final st = store.financialStatus(g);
      final financePending =
          st == FinancialStatus.unpaid || st == FinancialStatus.partial;
      return switch (_filter) {
        _PassFilter.all => true,
        _PassFilter.finance => financePending,
        _PassFilter.data => dataPending,
        _PassFilter.ok => !financePending && !dataPending,
      };
    }).toList();

    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) {
      groups = groups.where((g) {
        if (g.buyerName.toLowerCase().contains(q)) return true;
        final paxNames = g.passengerIds
            .map(store.passengerById)
            .whereType<Passenger>()
            .any((p) => p.name.toLowerCase().contains(q));
        return paxNames;
      }).toList();
    }

    return Column(
      children: [
        // Barra de filtros
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por comprador ou passageiro...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterBtn(
                      label: 'Todas',
                      selected: _filter == _PassFilter.all,
                      onTap: () => setState(() => _filter = _PassFilter.all),
                    ),
                    _FilterBtn(
                      label: 'Pend. financeira',
                      icon: Icons.error_outline,
                      color: AppColors.danger,
                      selected: _filter == _PassFilter.finance,
                      onTap: () =>
                          setState(() => _filter = _PassFilter.finance),
                    ),
                    _FilterBtn(
                      label: 'Pend. de dados',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      selected: _filter == _PassFilter.data,
                      onTap: () => setState(() => _filter = _PassFilter.data),
                    ),
                    _FilterBtn(
                      label: 'Tudo OK',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      selected: _filter == _PassFilter.ok,
                      onTap: () => setState(() => _filter = _PassFilter.ok),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),

        // Lista de passagens
        Expanded(
          child: groups.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhuma passagem',
                  subtitle:
                      'Registre quem pagou e quem viaja — o valor é dias × diária.',
                  action: canEdit
                      ? FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PassageFormPage(eventId: widget.eventId)),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nova passagem'),
                        )
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    final expected = store.expectedCentsForPassage(g);
                    final paid = g.paidCents;
                    final pending = expected - paid;
                    final st = store.financialStatus(g);
                    final names = g.passengerIds
                        .map(store.passengerById)
                        .whereType<Passenger>()
                        .map((p) => p.name)
                        .join(', ');

                    return _PassageCard(
                      group: g,
                      expected: expected,
                      paid: paid,
                      pending: pending,
                      status: st,
                      passengerNames: names,
                      canEdit: canEdit,
                      onAction: () =>
                          _openPassageActions(context, ref, g),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openPassageActions(
    BuildContext context,
    WidgetRef ref,
    PassageGroup group,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: AppColors.brand),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.buyerName,
                            style: Theme.of(ctx).textTheme.titleSmall),
                        Text('Escolha uma ação',
                            style: Theme.of(ctx).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.brand),
              ),
              title: const Text('Editar passagem'),
              subtitle: const Text('Comprador, forma de pagamento e passageiros'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.payments_outlined,
                    size: 18, color: AppColors.success),
              ),
              title: const Text('Registrar pagamento'),
              subtitle:
                  const Text('Soma ao valor recebido sem apagar o histórico'),
              onTap: () => Navigator.pop(ctx, 'pay'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassageFormPage(
            eventId: widget.eventId,
            passageId: group.id,
          ),
        ),
      );
      return;
    }
    if (action == 'pay') {
      await _addPayment(context, ref, group);
    }
  }

  Future<void> _addPayment(
      BuildContext context, WidgetRef ref, PassageGroup group) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.pix;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            title: Text('Pagamento — ${group.buyerName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Já recebido: ${AppFormatters.cents(group.paidCents)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.info),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor adicional (R\$)',
                    prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Seleção de método de pagamento
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pagamento',
                    prefixIcon: Icon(Icons.payment_outlined, size: 20),
                  ),
                  items: PaymentMethod.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedMethod = v ?? selectedMethod),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: 'Comprovante / nota',
                    hintText: selectedMethod == PaymentMethod.pix
                        ? 'Ex.: PIX 14/10'
                        : 'Ex.: dinheiro entregue em maos',
                    prefixIcon: const Icon(Icons.note_outlined, size: 20),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final reais = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    final store = ref.read(localStoreProvider);
    final result = store.addPayment(
      passageId: group.id,
      extraCents: (reais * 100).round(),
      method: selectedMethod,
      receiptNote: note.text,
    );
    if (context.mounted) await showStoreMessage(context, result);
  }
}

class _PassageCard extends StatelessWidget {
  final PassageGroup group;
  final int expected;
  final int paid;
  final int pending;
  final FinancialStatus status;
  final String passengerNames;
  final bool canEdit;
  final VoidCallback onAction;

  const _PassageCard({
    required this.group,
    required this.expected,
    required this.paid,
    required this.pending,
    required this.status,
    required this.passengerNames,
    required this.canEdit,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: canEdit ? onAction : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                    AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.buyerName,
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            [
                              group.paymentMethod.label,
                              if (group.deadlineBypass) 'após prazo',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    StatusChip.finance(status),
                    if (canEdit)
                      IconButton(
                        onPressed: onAction,
                        icon: const Icon(Icons.more_vert, size: 18),
                        color: cs.onSurfaceVariant,
                        tooltip: 'Ações',
                      ),
                  ],
                ),
              ),
              // Passageiros
              if (passengerNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          passengerNames,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              // Divisor
              Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
              // Valores financeiros
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _FinValue(
                        label: 'Esperado',
                        value: AppFormatters.cents(expected)),
                    const SizedBox(width: AppSpacing.lg),
                    _FinValue(
                      label: 'Recebido',
                      value: AppFormatters.cents(paid),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _FinValue(
                      label: 'Pendente',
                      value: pending > 0
                          ? AppFormatters.cents(pending)
                          : (pending < 0
                              ? '+ ${AppFormatters.cents(-pending)}'
                              : 'Quitado'),
                      color: pending > 0
                          ? AppColors.danger
                          : (pending < 0 ? AppColors.info : AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _FinValue({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color ?? cs.onSurface,
              ),
        ),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: selected ? (color ?? AppColors.brand) : null),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Check-in
// ─────────────────────────────────────────────────────────────────────────────

class CheckInTab extends ConsumerStatefulWidget {
  final String eventId;
  const CheckInTab({super.key, required this.eventId});

  @override
  ConsumerState<CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends ConsumerState<CheckInTab> {
  String? _dayId;
  String? _vehicleId;
  final _search = TextEditingController();
  bool _sortAlpha = true;
  bool _filterMinor = false;
  bool _filterStudent = false;
  String? _filterStopId;
  bool _filterRelocations = false;
  bool _filterDesisted = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _sortAlpha = true;
      _filterMinor = false;
      _filterStudent = false;
      _filterStopId = null;
      _filterRelocations = false;
      _filterDesisted = false;
    });
  }

  bool get _hasActiveFilters =>
      _search.text.isNotEmpty ||
      _filterMinor ||
      _filterStudent ||
      _filterStopId != null ||
      _filterRelocations ||
      _filterDesisted ||
      !_sortAlpha;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final event = store.eventById(widget.eventId)!;
    final user = store.user!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    if (!user.canCheckIn(event)) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Check-in bloqueado',
        subtitle: 'O coordenador ainda não liberou o check-in para o seu perfil.',
      );
    }

    final days = store.daysForEvent(widget.eventId);
    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Nenhum dia cadastrado',
        subtitle: 'Cadastre os dias do evento nas Configurações para realizar o check-in.',
      );
    }

    _dayId ??= days.first.id;
    if (!days.any((d) => d.id == _dayId)) {
      _dayId = days.first.id;
    }

    final vehicles = store.vehiclesForEvent(widget.eventId);
    if (vehicles.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'Nenhum veículo cadastrado',
        subtitle: 'Adicione ônibus na aba Ônibus para organizar os embarques.',
      );
    }

    _vehicleId ??= vehicles.first.id;
    if (!vehicles.any((v) => v.id == _vehicleId)) {
      _vehicleId = vehicles.first.id;
    }

    final currentVehicle = vehicles.firstWhere((v) => v.id == _vehicleId);
    final currentDay = days.firstWhere((d) => d.id == _dayId);

    // Alocações do veículo e dia selecionados
    final vehicleDayAllocs = store.allocationsForVehicleDay(currentVehicle.id, _dayId!);
    final activeAllocs = vehicleDayAllocs.where((a) => a.isActive).toList();

    // Contadores contextuais estritos (Veículo + Dia selecionados)
    final totalActive = activeAllocs.length;
    final outboundDone = activeAllocs.where((a) => store.hasCheckIn(a.id, 'OUTBOUND')).length;
    final outboundPending = totalActive - outboundDone;
    final returnDone = activeAllocs.where((a) => store.hasCheckIn(a.id, 'RETURN')).length;
    final returnPending = totalActive - returnDone;

    // Aplicação dos filtros para a lista de exibição
    List<Allocation> displayList;
    if (_filterDesisted) {
      displayList = vehicleDayAllocs.where((a) => a.status == AllocationStatus.desisted).toList();
    } else if (_filterRelocations) {
      displayList = vehicleDayAllocs.where((a) => a.status == AllocationStatus.relocated || a.replacedPassengerId != null).toList();
    } else {
      displayList = List<Allocation>.from(activeAllocs);
    }

    // Filtro por parada
    if (_filterStopId != null) {
      displayList = displayList.where((a) => a.stopId == _filterStopId).toList();
    }

    // Filtro menores
    if (_filterMinor) {
      displayList = displayList.where((a) {
        final p = store.passengerById(a.passengerId);
        if (p == null) return false;
        if (p.category == PassengerCategory.minor) return true;
        if (p.birthDate != null) {
          return DomainCalculations.calculateAgeOnDate(
                birthDate: p.birthDate!,
                targetDate: event.startDate,
              ) <
              18;
        }
        return false;
      }).toList();
    }

    // Filtro estudantes
    if (_filterStudent) {
      displayList = displayList.where((a) {
        final p = store.passengerById(a.passengerId);
        return p?.category == PassengerCategory.student;
      }).toList();
    }

    // Busca textual por nome
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      displayList = displayList.where((a) {
        final p = store.passengerById(a.passengerId);
        return p != null && p.name.toLowerCase().contains(query);
      }).toList();
    }

    // Ordenação alfabética
    if (_sortAlpha) {
      displayList.sort((a, b) {
        final nameA = store.passengerById(a.passengerId)?.name.toLowerCase() ?? '';
        final nameB = store.passengerById(b.passengerId)?.name.toLowerCase() ?? '';
        return nameA.compareTo(nameB);
      });
    }

    return Column(
      children: [
        // ── 1. Barra de Seleção: Dia do Evento & Veículo ──
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção de Dia
              Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 16, color: AppColors.brand),
                  const SizedBox(width: 6),
                  Text(
                    'Dia:',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: days.map((d) {
                          final isSel = _dayId == d.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(d.label),
                              selected: isSel,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() {
                                _dayId = d.id;
                                _filterStopId = null;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Seleção de Veículo
              Row(
                children: [
                  const Icon(Icons.directions_bus_outlined, size: 16, color: AppColors.brand),
                  const SizedBox(width: 6),
                  Text(
                    'Veículo:',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vehicles.map((v) {
                          final isSel = _vehicleId == v.id;
                          final occ = store
                              .allocationsForVehicleDay(v.id, _dayId!)
                              .where((a) => a.isActive)
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: Icon(
                                v.type == VehicleType.bus ? Icons.directions_bus : Icons.directions_car,
                                size: 14,
                              ),
                              label: Text('${v.name} ($occ/${v.localCapacity})'),
                              selected: isSel,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() {
                                _vehicleId = v.id;
                                _filterStopId = null;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

        // ── 2. Resumo de Contadores Contextuais ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: isDark ? AppColors.canvasDark : AppColors.canvasLight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              final cards = [
                _CheckInMetricCard(
                  title: 'Passageiros na Lista',
                  value: '$totalActive',
                  subtitle: '${currentVehicle.name} · ${currentDay.label}',
                  accentColor: AppColors.brand,
                  icon: Icons.people_outline_rounded,
                ),
                _CheckInMetricCard(
                  title: 'Check-in Ida',
                  value: '$outboundDone de $totalActive',
                  subtitle: outboundPending == 0 && totalActive > 0
                      ? 'Todos embarcados!'
                      : '$outboundPending pendente(s)',
                  accentColor: outboundDone == totalActive && totalActive > 0
                      ? AppColors.success
                      : (outboundDone > 0 ? AppColors.brand : AppColors.warning),
                  icon: Icons.flight_takeoff_rounded,
                  progress: totalActive == 0 ? 0 : outboundDone / totalActive,
                ),
                _CheckInMetricCard(
                  title: 'Check-in Volta',
                  value: '$returnDone de $totalActive',
                  subtitle: returnPending == 0 && totalActive > 0
                      ? 'Todos embarcados!'
                      : '$returnPending pendente(s)',
                  accentColor: returnDone == totalActive && totalActive > 0
                      ? AppColors.success
                      : (returnDone > 0 ? AppColors.info : AppColors.warning),
                  icon: Icons.flight_land_rounded,
                  progress: totalActive == 0 ? 0 : returnDone / totalActive,
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cards.map((c) => SizedBox(width: 200, child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList(),
                  ),
                );
              }
            },
          ),
        ),

        // ── 3. Barra de Busca e Filtros Avançados ──
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha de Busca Textual
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar passageiro por nome...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Linha de Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.sort_by_alpha_rounded, size: 14),
                      label: const Text('A–Z'),
                      selected: _sortAlpha,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) => setState(() => _sortAlpha = val),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: const Icon(Icons.child_care_rounded, size: 14),
                      label: const Text('Menores'),
                      selected: _filterMinor,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) => setState(() => _filterMinor = val),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: const Icon(Icons.school_rounded, size: 14),
                      label: const Text('Estudantes'),
                      selected: _filterStudent,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) => setState(() => _filterStudent = val),
                    ),
                    const SizedBox(width: 6),
                    // Seletor de Ponto de Parada
                    if (currentVehicle.stops.isNotEmpty)
                      PopupMenuButton<String?>(
                        onSelected: (stopId) => setState(() => _filterStopId = stopId),
                        child: Chip(
                          avatar: const Icon(Icons.pin_drop_outlined, size: 14),
                          label: Text(
                            _filterStopId == null
                                ? 'Parada: Todas'
                                : 'Parada: ${store.stopById(currentVehicle.id, _filterStopId!)?.name ?? '—'}',
                          ),
                          backgroundColor: _filterStopId != null
                              ? AppColors.brand.withValues(alpha: 0.15)
                              : null,
                          deleteIcon: _filterStopId != null
                              ? const Icon(Icons.close, size: 14)
                              : const Icon(Icons.arrow_drop_down, size: 16),
                          onDeleted: _filterStopId != null
                              ? () => setState(() => _filterStopId = null)
                              : null,
                          visualDensity: VisualDensity.compact,
                        ),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('Todas as paradas'),
                          ),
                          ...currentVehicle.stops.map(
                            (s) => PopupMenuItem<String?>(
                              value: s.id,
                              child: Text('#${s.sequence} - ${s.name}'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: const Icon(Icons.swap_horiz_rounded, size: 14),
                      label: const Text('Realocações'),
                      selected: _filterRelocations,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) => setState(() {
                        _filterRelocations = val;
                        if (val) _filterDesisted = false;
                      }),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: const Icon(Icons.cancel_outlined, size: 14),
                      label: const Text('Desistências'),
                      selected: _filterDesisted,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) => setState(() {
                        _filterDesisted = val;
                        if (val) _filterRelocations = false;
                      }),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.filter_alt_off_outlined, size: 14),
                        label: const Text('Limpar filtros'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _clearFilters,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

        // ── 4. Lista de Passageiros do Veículo ──
        Expanded(
          child: displayList.isEmpty
              ? EmptyState(
                  icon: _filterDesisted
                      ? Icons.cancel_outlined
                      : (_filterRelocations
                          ? Icons.swap_horiz_rounded
                          : Icons.how_to_reg_outlined),
                  title: _filterDesisted
                      ? 'Nenhuma desistência registrada'
                      : (_filterRelocations
                          ? 'Nenhuma realocação registrada'
                          : (_hasActiveFilters
                              ? 'Nenhum passageiro encontrado com esses filtros'
                              : 'Nenhum passageiro alocado')),
                  subtitle: _hasActiveFilters
                      ? 'Tente ajustar ou limpar os filtros de busca.'
                      : 'Aloque passageiros neste ônibus na aba "Ônibus" para gerenciar o check-in.',
                  action: _hasActiveFilters
                      ? OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                          label: const Text('Limpar filtros'),
                        )
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  itemBuilder: (context, i) {
                    final a = displayList[i];
                    final p = store.passengerById(a.passengerId);
                    final stop = a.stopId != null ? store.stopById(a.vehicleId, a.stopId!) : null;
                    final outDone = store.hasCheckIn(a.id, 'OUTBOUND');
                    final returnDone = store.hasCheckIn(a.id, 'RETURN');
                    final sub = a.substitutePassengerId != null ? store.passengerById(a.substitutePassengerId!) : null;
                    final replaced = a.replacedPassengerId != null ? store.passengerById(a.replacedPassengerId!) : null;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar de status / posição
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: outDone && returnDone
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.brand.withValues(alpha: 0.08),
                            child: Icon(
                              outDone && returnDone
                                  ? Icons.done_all_rounded
                                  : Icons.person_outline_rounded,
                              size: 18,
                              color: outDone && returnDone ? AppColors.success : AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Dados do passageiro, categoria, parada e situação
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        p?.name ?? 'Passageiro',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: a.status == AllocationStatus.desisted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (p?.category == PassengerCategory.minor) ...[
                                      const SizedBox(width: 6),
                                      const StatusChip(label: 'Menor', icon: Icons.child_care_rounded),
                                    ],
                                    if (p?.category == PassengerCategory.student) ...[
                                      const SizedBox(width: 6),
                                      const StatusChip(label: 'Estudante', icon: Icons.school_rounded),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    // Ponto de Parada
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.pin_drop_outlined, size: 13, color: AppColors.brand),
                                        const SizedBox(width: 3),
                                        Text(
                                          stop != null ? stop.name : 'Parada não informada',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Situação da alocação
                                    if (a.status == AllocationStatus.desisted)
                                      Text(
                                        sub != null ? 'Desistiu (Substituído por ${sub.name})' : 'Desistente',
                                        style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                                      )
                                    else if (a.status == AllocationStatus.relocated)
                                      const Text(
                                        'Realocado para outro ônibus',
                                        style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                                      )
                                    else if (replaced != null)
                                      Text(
                                        'Substituto de ${replaced.name}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),

                          // Controles de Check-in (Ida e Volta)
                          if (a.isActive) ...[
                            _CheckButton(
                              label: 'Ida',
                              done: outDone,
                              onTap: () async {
                                final r = store.performCheckIn(a.id, 'OUTBOUND');
                                if (context.mounted) await showStoreMessage(context, r);
                              },
                              onUndo: () async {
                                final ok = await confirmDialog(
                                  context,
                                  'Deseja desfazer o check-in de IDA de ${p?.name}?',
                                );
                                if (ok) {
                                  final r = store.revertCheckIn(a.id, 'OUTBOUND');
                                  if (context.mounted) await showStoreMessage(context, r);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            _CheckButton(
                              label: 'Volta',
                              done: returnDone,
                              onTap: () async {
                                final r = store.performCheckIn(a.id, 'RETURN');
                                if (context.mounted) await showStoreMessage(context, r);
                              },
                              onUndo: () async {
                                final ok = await confirmDialog(
                                  context,
                                  'Deseja desfazer o check-in de VOLTA de ${p?.name}?',
                                );
                                if (ok) {
                                  final r = store.revertCheckIn(a.id, 'RETURN');
                                  if (context.mounted) await showStoreMessage(context, r);
                                }
                              },
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                a.status == AllocationStatus.desisted ? 'Desistente' : 'Inativo',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CheckInMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final double? progress;

  const _CheckInMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: accentColor, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback? onUndo;

  const _CheckButton({
    required this.label,
    required this.done,
    required this.onTap,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return done
        ? InkWell(
            onTap: onUndo,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              side: const BorderSide(color: AppColors.brand),
              foregroundColor: AppColors.brand,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Histórico
// ─────────────────────────────────────────────────────────────────────────────

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

class SettingsTab extends ConsumerWidget {
  final TransportEvent event;
  const SettingsTab({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Seção: permissões de check-in
        _SettingsSection(
          title: 'Permissões de check-in',
          icon: Icons.how_to_reg_outlined,
          children: [
            SwitchListTile(
              title: const Text('Capitão pode fazer check-in'),
              subtitle: const Text('Libera o perfil Capitão para registrar entrada/saída'),
              value: event.captainCheckinEnabled,
              onChanged: (v) =>
                  store.updateEvent(event.copyWith(captainCheckinEnabled: v)),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            SwitchListTile(
              title: const Text('Ajudante do capitão pode fazer check-in'),
              subtitle: const Text('Libera o perfil Ajudante para registrar entrada/saída'),
              value: event.helperCheckinEnabled,
              onChanged: (v) =>
                  store.updateEvent(event.copyWith(helperCheckinEnabled: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Seção: dados de demonstração
        _SettingsSection(
          title: 'Dados de demonstração',
          icon: Icons.restore_outlined,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.restore_rounded,
                    size: 18, color: AppColors.danger),
              ),
              title: const Text('Restaurar dados de demonstração'),
              subtitle: const Text(
                  'Substitui todos os dados locais pelos dados de exemplo. Esta ação não pode ser desfeita.'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  'Isso substitui todos os dados locais pelo exemplo. Seus eventos, passagens e histórico serão apagados.',
                  title: 'Restaurar demonstração',
                );
                if (ok && context.mounted) await store.resetDemo();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.brand)),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showVehicleSheet — bottom sheet de criação/edição de veículo com paradas
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showVehicleSheet(
  BuildContext context,
  WidgetRef ref,
  String eventId, {
  Vehicle? existing,
}) async {
  const uuid = Uuid();
  final name = TextEditingController(text: existing?.name ?? '');
  final physical = TextEditingController(
      text: '${existing?.physicalCapacity ?? 46}');
  final local =
      TextEditingController(text: '${existing?.localCapacity ?? 30}');
  var type = existing?.type ?? VehicleType.bus;
  final stops = <VehicleStop>[...(existing?.stops ?? const [])];
  final reassignStops = <String, String>{};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final theme = Theme.of(ctx);
            final cs = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        existing == null
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        existing == null ? 'Novo veículo' : 'Editar veículo',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome do veículo',
                      hintText: 'Ex.: Ônibus 1',
                      prefixIcon: Icon(Icons.directions_bus_outlined, size: 20),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<VehicleType>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: VehicleType.values
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setLocal(() => type = v ?? type),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: physical,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capacidade física',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: local,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Limite local',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Seção de Pontos de Parada
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.brand),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Pontos de Parada (${stops.length})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () async {
                          final stopNameCtrl = TextEditingController();
                          final stopRefCtrl = TextEditingController();
                          final added = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Nova Parada'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: stopNameCtrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do ponto *',
                                      hintText: 'Ex.: Praça Central',
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: stopRefCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Referência / Endereço (opcional)',
                                      hintText: 'Ex.: Ao lado da igreja',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  child: const Text('Adicionar'),
                                ),
                              ],
                            ),
                          );
                          if (added == true && stopNameCtrl.text.trim().isNotEmpty) {
                            setLocal(() {
                              final newSeq = stops.isEmpty ? 1 : stops.length + 1;
                              stops.add(
                                VehicleStop(
                                  id: uuid.v4(),
                                  name: stopNameCtrl.text.trim(),
                                  reference: stopRefCtrl.text.trim().isEmpty ? null : stopRefCtrl.text.trim(),
                                  sequence: newSeq,
                                ),
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar parada'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cadastre e ordene os pontos de embarque do trajeto deste veículo.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (stops.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.canvasLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Text(
                        'Nenhum ponto cadastrado. Clique em "+ Adicionar parada" para definir o itinerário.',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...List.generate(stops.length, (idx) {
                      final s = stops[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  if (s.reference != null && s.reference!.isNotEmpty)
                                    Text(
                                      s.reference!,
                                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              tooltip: 'Mover para cima',
                              onPressed: idx > 0
                                  ? () {
                                      setLocal(() {
                                        final item = stops.removeAt(idx);
                                        stops.insert(idx - 1, item);
                                        for (var k = 0; k < stops.length; k++) {
                                          stops[k] = stops[k].copyWith(sequence: k + 1);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              tooltip: 'Mover para baixo',
                              onPressed: idx < stops.length - 1
                                  ? () {
                                      setLocal(() {
                                        final item = stops.removeAt(idx);
                                        stops.insert(idx + 1, item);
                                        for (var k = 0; k < stops.length; k++) {
                                          stops[k] = stops[k].copyWith(sequence: k + 1);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              tooltip: 'Editar parada',
                              onPressed: () async {
                                final editName = TextEditingController(text: s.name);
                                final editRef = TextEditingController(text: s.reference ?? '');
                                final updated = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Editar Parada'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: editName,
                                          decoration: const InputDecoration(labelText: 'Nome do ponto *'),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        TextField(
                                          controller: editRef,
                                          decoration: const InputDecoration(labelText: 'Referência (opcional)'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
                                      FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Salvar')),
                                    ],
                                  ),
                                );
                                if (updated == true && editName.text.trim().isNotEmpty) {
                                  setLocal(() {
                                    stops[idx] = s.copyWith(
                                      name: editName.text.trim(),
                                      reference: editRef.text.trim().isEmpty ? null : editRef.text.trim(),
                                    );
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              tooltip: 'Remover parada',
                              onPressed: () async {
                                if (existing != null) {
                                  final store = ref.read(localStoreProvider);
                                  final activeWithStop = store.allocationsForStop(existing.id, s.id);
                                  if (activeWithStop.isNotEmpty) {
                                    final otherStops = stops.where((other) => other.id != s.id).toList();
                                    if (otherStops.isEmpty) {
                                      await showDialog<void>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text('Parada com passageiros'),
                                          content: Text(
                                            'A parada "${s.name}" possui ${activeWithStop.length} passageiro(s) ativo(s) associado(s). '
                                            'Cadastre outra parada antes de removê-la para reatribuir os passageiros.',
                                          ),
                                          actions: [
                                            FilledButton(
                                              onPressed: () => Navigator.pop(dCtx),
                                              child: const Text('Entendido'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    VehicleStop? targetStop = otherStops.first;
                                    final confirmed = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dCtx) => StatefulBuilder(
                                        builder: (dCtx, setDCtx) => AlertDialog(
                                          title: const Text('Reatribuir passageiros da parada'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'A parada "${s.name}" possui ${activeWithStop.length} passageiro(s) ativo(s) associado(s). '
                                                'Selecione para qual parada esses passageiros serão transferidos:',
                                              ),
                                              const SizedBox(height: AppSpacing.md),
                                              DropdownButtonFormField<VehicleStop>(
                                                value: targetStop,
                                                isExpanded: true,
                                                items: otherStops.map((os) => DropdownMenuItem(value: os, child: Text(os.name))).toList(),
                                                onChanged: (val) => setDCtx(() => targetStop = val),
                                                decoration: const InputDecoration(labelText: 'Nova parada'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
                                            FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Confirmar e remover')),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (confirmed != true || targetStop == null) return;
                                    reassignStops[s.id] = targetStop!.id;
                                  }
                                }
                                setLocal(() {
                                  stops.removeAt(idx);
                                  for (var k = 0; k < stops.length; k++) {
                                    stops[k] = stops[k].copyWith(sequence: k + 1);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () async {
                      final store = ref.read(localStoreProvider);
                      final result = existing == null
                          ? store.addVehicle(
                              eventId: eventId,
                              name: name.text,
                              type: type,
                              physicalCapacity:
                                  int.tryParse(physical.text) ?? 0,
                              localCapacity:
                                  int.tryParse(local.text) ?? 0,
                              stops: stops,
                            )
                          : store.updateVehicle(
                              existing.copyWith(
                                name: name.text.trim(),
                                type: type,
                                physicalCapacity:
                                    int.tryParse(physical.text) ?? 0,
                                localCapacity:
                                    int.tryParse(local.text) ?? 0,
                                stops: stops,
                              ),
                              reassignStops: reassignStops,
                            );
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        await showStoreMessage(context, result);
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Salvar veículo'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
