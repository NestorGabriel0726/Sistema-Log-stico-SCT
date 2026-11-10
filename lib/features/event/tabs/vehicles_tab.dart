import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/local_app_store.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import 'vehicle_sheet.dart';

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
    final user = store.user!;
    var vehicles = store.vehiclesForEvent(widget.eventId);
    if (user.role == UserRole.captain || user.role == UserRole.captainHelper) {
      vehicles = vehicles.where((v) => v.id == user.assignedVehicleId).toList();
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    if (vehicles.isEmpty) {
      final isCaptain = user.role == UserRole.captain || user.role == UserRole.captainHelper;
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: isCaptain ? 'Nenhum veículo atribuído' : 'Nenhum veículo cadastrado',
        subtitle: isCaptain
            ? 'Você ainda não possui veículo designado para este evento. Contate o coordenador.'
            : 'Adicione ônibus ou carros conforme a demanda das passagens.',
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

