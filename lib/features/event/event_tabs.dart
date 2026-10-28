import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/local_app_store.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';
import 'passage_form_page.dart';

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
    final result =
        store.allocate(passengerId: chosen.id, vehicleId: vehicle.id, dayId: dayId);
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
                if (statusLabel != null || p?.category != null)
                  Text(
                    [
                      if (p?.category != null) p!.category.label,
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
  var result =
      store.relocate(allocationId: allocation.id, targetVehicleId: dest.id);
  if (result.needsConfirm) {
    final ok = await confirmDialog(context, result.message);
    if (ok) {
      result = store.relocate(
          allocationId: allocation.id,
          targetVehicleId: dest.id,
          confirmed: true);
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
      _PaxFilter.exempt => list.where((p) => p.isExempt).toList(),
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
                          if (store.user?.canViewFinance == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              p.isExempt
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
    final cs = theme.colorScheme;
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagamento — ${group.buyerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Já recebido: ${AppFormatters.cents(group.paidCents)}',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodySmall
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
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Comprovante / nota',
                hintText: 'Ex.: PIX 14/10',
                prefixIcon: Icon(Icons.note_outlined, size: 20),
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
      ),
    );
    if (ok != true || !context.mounted) return;
    final reais = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    final store = ref.read(localStoreProvider);
    final result = store.addPayment(
      passageId: group.id,
      extraCents: (reais * 100).round(),
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
  String? _dayFilter;

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
    var allocs = store.allocationsForEvent(widget.eventId);

    if (allocs.isEmpty) {
      return const EmptyState(
        icon: Icons.how_to_reg_outlined,
        title: 'Nenhuma alocação',
        subtitle: 'Aloque passageiros nos ônibus primeiro.',
      );
    }

    // Filtragem por dia
    if (_dayFilter != null) {
      allocs = allocs.where((a) => a.dayId == _dayFilter).toList();
    }

    return Column(
      children: [
        // Filtro por dia
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: const Text('Todos'),
                          selected: _dayFilter == null,
                          onSelected: (_) =>
                              setState(() => _dayFilter = null),
                        ),
                      ),
                      ...days.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(d.label),
                            selected: _dayFilter == d.id,
                            onSelected: (_) =>
                                setState(() => _dayFilter = d.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ],
            ),
          ),

        // Lista de check-in
        Expanded(
          child: allocs.isEmpty
              ? const EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'Nenhum passageiro neste dia',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: allocs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    indent: 56,
                  ),
                  itemBuilder: (context, i) {
                    final a = allocs[i];
                    final p = store.passengerById(a.passengerId);
                    final v = store.vehicleById(a.vehicleId);
                    final out = store.hasCheckIn(a.id, 'OUTBOUND');
                    final back = store.hasCheckIn(a.id, 'RETURN');
                    final bothDone = out && back;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: bothDone
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.brand.withValues(alpha: 0.1),
                        child: Icon(
                          bothDone
                              ? Icons.check_rounded
                              : Icons.person_outline_rounded,
                          size: 18,
                          color: bothDone ? AppColors.success : AppColors.brand,
                        ),
                      ),
                      title: Text(
                        p?.name ?? 'Passageiro',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          v?.name ?? '',
                          if (_dayFilter == null) ...[
                            for (final d in days)
                              if (d.id == a.dayId) d.label,
                          ],
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: LayoutBuilder(
                        builder: (context, constraints) {
                          // Adapta o layout de check-in ao espaço disponível
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CheckButton(
                                label: 'Ida',
                                done: out,
                                onTap: () async {
                                  final r = store.performCheckIn(
                                      a.id, 'OUTBOUND');
                                  if (context.mounted) {
                                    await showStoreMessage(context, r);
                                  }
                                },
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _CheckButton(
                                label: 'Volta',
                                done: back,
                                onTap: () async {
                                  final r =
                                      store.performCheckIn(a.id, 'RETURN');
                                  if (context.mounted) {
                                    await showStoreMessage(context, r);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _CheckButton({
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return done
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(60, 32),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
// showVehicleSheet — bottom sheet de criação/edição de veículo
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showVehicleSheet(
  BuildContext context,
  WidgetRef ref,
  String eventId, {
  Vehicle? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final physical = TextEditingController(
      text: '${existing?.physicalCapacity ?? 46}');
  final local =
      TextEditingController(text: '${existing?.localCapacity ?? 30}');
  var type = existing?.type ?? VehicleType.bus;

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
            return Column(
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
                          )
                        : store.updateVehicle(
                            Vehicle(
                              id: existing.id,
                              eventId: eventId,
                              name: name.text,
                              type: type,
                              physicalCapacity:
                                  int.tryParse(physical.text) ?? 0,
                              localCapacity:
                                  int.tryParse(local.text) ?? 0,
                            ),
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
            );
          },
        ),
      );
    },
  );
}
