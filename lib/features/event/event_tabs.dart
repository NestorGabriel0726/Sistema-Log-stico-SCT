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
    final activity = store.activityForEvent(eventId).take(5).toList();
    final maxDay = perDay.fold<int>(1, (m, d) => d.passengers > m ? d.passengers : m);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _DeadlineStrip(event: event),
        const SizedBox(height: AppSpacing.md),
        if (showFinance)
          Row(
            children: [
              Expanded(child: _Metric('Esperado', AppFormatters.cents(finance.expectedCents), AppColors.brand)),
              const SizedBox(width: 8),
              Expanded(child: _Metric('Recebido', AppFormatters.cents(finance.paidCents), AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _Metric('Pendente', AppFormatters.cents(finance.pendingCents), AppColors.danger)),
            ],
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Resumo financeiro visível apenas para coordenação.'),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Passageiros por dia', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (perDay.isEmpty)
          const Text('Sem dias cadastrados.')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: perDay
                .map(
                  (d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text('${d.passengers}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Container(
                            height: 12 + (80 * (d.passengers / maxDay)),
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(d.label.split('-').first, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Lotação', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ...stats.map(
          (s) => CapacityBar(
            ratio: s.ratio,
            label: '${s.vehicleName} • ${s.dayLabel}',
            trailing: '${s.occupied}/${s.capacity}',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Atividade recente', style: Theme.of(context).textTheme.titleMedium),
        ...activity.map(
          (a) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(a.message),
            subtitle: Text('${a.actorName} • ${AppFormatters.date(a.at)}'),
          ),
        ),
      ],
    );
  }
}

class _DeadlineStrip extends StatelessWidget {
  final TransportEvent event;
  const _DeadlineStrip({required this.event});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Passagens', event.passageDeadline),
      ('Lista prévia', event.preliminaryListDeadline),
      ('Lista definitiva', event.finalListDeadline),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        final late = e.$2 != null && DateTime.now().isAfter(e.$2!);
        return TagChip(
          label: '${e.$1}: ${e.$2 == null ? '—' : AppFormatters.date(e.$2!)}',
          color: late ? AppColors.danger.withValues(alpha: 0.12) : null,
          foreground: late ? AppColors.danger : null,
        );
      }).toList(),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

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

    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'Nenhum veículo',
        subtitle: 'Crie ônibus ou carros conforme a demanda real das passagens.',
        action: user.canEditOperations
            ? FilledButton(
                onPressed: () => showVehicleSheet(context, ref, widget.eventId),
                child: const Text('Adicionar veículo'),
              )
            : null,
      );
    }

    return Column(
      children: [
        if (days.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: days
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(d.label),
                        selected: _dayId == d.id,
                        onSelected: (_) => setState(() => _dayId = d.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final v = vehicles[i];
              final dayId = _dayId;
              final rows = dayId == null ? <Allocation>[] : store.allocationsForVehicleDay(v.id, dayId);
              final occupied = rows.where((a) => a.isActive).length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${v.name} • ${v.type.label}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (user.canEditOperations)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => showVehicleSheet(context, ref, widget.eventId, existing: v),
                            ),
                        ],
                      ),
                      Text(
                        '$occupied/${v.localCapacity} vagas locais (físico ${v.physicalCapacity})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      CapacityBar(
                        ratio: v.localCapacity == 0 ? 0 : occupied / v.localCapacity,
                        label: 'Lotação do dia',
                        trailing: '$occupied/${v.localCapacity}',
                      ),
                      if (rows.isEmpty)
                        const Text('Lista vazia neste dia.')
                      else
                        ...rows.map((a) => _AllocationTile(allocation: a, eventId: widget.eventId)),
                      if (user.canEditOperations && dayId != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _allocateSheet(context, ref, v, dayId),
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Alocar passageiro'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _allocateSheet(BuildContext context, WidgetRef ref, Vehicle vehicle, String dayId) async {
    final store = ref.read(localStoreProvider);
    final options = store.unallocatedOnDay(widget.eventId, dayId);
    if (options.isEmpty) {
      await showStoreMessage(context, const StoreResult.error('Não há passageiros livres neste dia.'));
      return;
    }
    final chosen = await showModalBottomSheet<Passenger>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(title: Text('Quem entra nesta lista?')),
          ...options.map(
            (p) => ListTile(
              title: Text(p.name),
              subtitle: Text(p.category.label),
              onTap: () => Navigator.pop(ctx, p),
            ),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    final result = store.allocate(passengerId: chosen.id, vehicleId: vehicle.id, dayId: dayId);
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

    Widget title;
    if (allocation.status == AllocationStatus.desisted && sub != null) {
      title = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: name, style: const TextStyle(decoration: TextDecoration.lineThrough)),
            const TextSpan(text: '  →  '),
            TextSpan(text: sub.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    } else if (allocation.status == AllocationStatus.desisted) {
      title = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: name, style: const TextStyle(decoration: TextDecoration.lineThrough)),
            const TextSpan(text: '  [Desistente]'),
          ],
        ),
      );
    } else if (allocation.status == AllocationStatus.relocated) {
      title = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: name, style: const TextStyle(decoration: TextDecoration.lineThrough)),
            TextSpan(text: '  →  🟡 Relocado para ${dest?.name ?? 'outro ônibus'}'),
          ],
        ),
      );
    } else if (replaced != null) {
      title = Text('$name  (substituto de ${replaced.name})');
    } else {
      title = Text(name);
    }

    return ListTile(
      dense: true,
      leading: Text('#${allocation.position}', style: const TextStyle(fontWeight: FontWeight.w800)),
      title: title,
      subtitle: p == null ? null : Text(p.category.label),
      trailing: allocation.isActive && store.user?.canEditOperations == true
          ? PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'desist') {
                  await _desistFlow(context, ref, allocation);
                } else if (value == 'move') {
                  await _relocateFlow(context, ref, allocation);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'desist', child: Text('Desistência')),
                PopupMenuItem(value: 'move', child: Text('Realocar')),
              ],
            )
          : null,
    );
  }
}

Future<void> _relocateFlow(BuildContext context, WidgetRef ref, Allocation allocation) async {
  final store = ref.read(localStoreProvider);
  final passenger = store.passengerById(allocation.passengerId);
  final vehicles = store.vehiclesForEvent(passenger!.eventId).where((v) => v.id != allocation.vehicleId);
  final dest = await showModalBottomSheet<Vehicle>(
    context: context,
    builder: (ctx) => ListView(
      children: [
        const ListTile(title: Text('Mover para')),
        ...vehicles.map((v) => ListTile(title: Text(v.name), onTap: () => Navigator.pop(ctx, v))),
      ],
    ),
  );
  if (dest == null) return;
  var result = store.relocate(allocationId: allocation.id, targetVehicleId: dest.id);
  if (result.needsConfirm) {
    final ok = await confirmDialog(context, result.message);
    if (ok) {
      result = store.relocate(allocationId: allocation.id, targetVehicleId: dest.id, confirmed: true);
    } else {
      return;
    }
  }
  if (context.mounted) await showStoreMessage(context, result);
}

Future<void> _desistFlow(BuildContext context, WidgetRef ref, Allocation allocation) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Desistência'),
      content: const Text('Haverá substituto nesta vaga?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, 'none'), child: const Text('Vaga seca')),
        FilledButton(onPressed: () => Navigator.pop(ctx, 'sub'), child: const Text('Com substituto')),
      ],
    ),
  );
  if (choice == null) return;
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
      title: const Text('Substituto'),
      content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return;
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

class PassengersTab extends ConsumerStatefulWidget {
  final String eventId;
  const PassengersTab({super.key, required this.eventId});

  @override
  ConsumerState<PassengersTab> createState() => _PassengersTabState();
}

enum _PaxFilter { all, alpha, unpaid, missingDoc, minor, student, exempt }

class _PassengersTabState extends ConsumerState<PassengersTab> {
  _PaxFilter _filter = _PaxFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final event = store.eventById(widget.eventId)!;
    var list = store.passengersForEvent(widget.eventId);

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
      _PaxFilter.minor => list.where((p) => p.category == PassengerCategory.minor).toList(),
      _PaxFilter.student => list.where((p) => p.category == PassengerCategory.student).toList(),
      _PaxFilter.exempt => list.where((p) => p.isExempt).toList(),
    };

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(icon: Icons.people_outline, title: 'Nenhum passageiro neste filtro')
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final p = list[i];
                    final passage = store.passageById(p.passageId);
                    final due = store.expectedCentsForPassenger(p, event);
                    return ListTile(
                      leading: CircleAvatar(child: Text(p.name.isEmpty ? '?' : p.name[0])),
                      title: Text(p.name),
                      subtitle: Text(
                        [
                          p.category.label,
                          if (passage != null) 'Passagem: ${passage.buyerName}',
                          if (p.missingDocument) 'Doc. pendente',
                          if (p.missingResponsible) 'Responsável pendente',
                          '${p.dayIds.length} dia(s)',
                        ].join(' • '),
                      ),
                      trailing: store.user?.canViewFinance == true
                          ? Text(p.isExempt ? 'Isento' : AppFormatters.cents(due))
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PassagesTab extends ConsumerStatefulWidget {
  final String eventId;
  const PassagesTab({super.key, required this.eventId});

  @override
  ConsumerState<PassagesTab> createState() => _PassagesTabState();
}

enum _PassFilter { all, finance, data, ok }

class _PassagesTabState extends ConsumerState<PassagesTab> {
  _PassFilter _filter = _PassFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final groups = store.passagesForEvent(widget.eventId).where((g) {
      final pax = g.passengerIds.map(store.passengerById).whereType<Passenger>();
      final dataPending = pax.any((p) => p.hasDataPending);
      final st = store.financialStatus(g);
      final financePending = st == FinancialStatus.unpaid || st == FinancialStatus.partial;
      return switch (_filter) {
        _PassFilter.all => true,
        _PassFilter.finance => financePending,
        _PassFilter.data => dataPending,
        _PassFilter.ok => !financePending && !dataPending,
      };
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(label: const Text('Tudo'), selected: _filter == _PassFilter.all, onSelected: (_) => setState(() => _filter = _PassFilter.all)),
              FilterChip(label: const Text('Pendência financeira'), selected: _filter == _PassFilter.finance, onSelected: (_) => setState(() => _filter = _PassFilter.finance)),
              FilterChip(label: const Text('Pendência de dados'), selected: _filter == _PassFilter.data, onSelected: (_) => setState(() => _filter = _PassFilter.data)),
              FilterChip(label: const Text('Tudo OK'), selected: _filter == _PassFilter.ok, onSelected: (_) => setState(() => _filter = _PassFilter.ok)),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhuma passagem',
                  subtitle: 'Registre quem pagou e quem viaja — o valor é dias × diária.',
                  action: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PassageFormPage(eventId: widget.eventId)),
                    ),
                    child: const Text('Nova passagem'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    final expected = store.expectedCentsForPassage(g);
                    final st = store.financialStatus(g);
                    final names = g.passengerIds.map(store.passengerById).whereType<Passenger>().map((p) => p.name).join(', ');
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(g.buyerName),
                          subtitle: Text(
                            '${g.paymentMethod.label} • $names'
                            '${g.deadlineBypass ? ' • após prazo' : ''}'
                            '${g.receiptNotes.isEmpty ? '' : '\n${g.receiptNotes.join(', ')}'}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TagChip.finance(st),
                              Text(
                                AppFormatters.cents(g.paidCents),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'de ${AppFormatters.cents(expected)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          onTap: store.user?.canEditOperations == true
                              ? () => _openPassageActions(context, ref, g)
                              : null,
                        ),
                      ),
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
            ListTile(
              title: Text(group.buyerName),
              subtitle: const Text('Escolha uma ação'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar passagem'),
              subtitle: const Text('Comprador, forma de pagamento e passageiros'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Registrar pagamento'),
              subtitle: const Text('Soma ao valor já recebido, sem apagar o histórico'),
              onTap: () => Navigator.pop(ctx, 'pay'),
            ),
            const SizedBox(height: 8),
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

  Future<void> _addPayment(BuildContext context, WidgetRef ref, PassageGroup group) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagamento — ${group.buyerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Já recebido: ${AppFormatters.cents(group.paidCents)}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor adicional (R\$)'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Comprovante / nota'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Fechar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
        ],
      ),
    );
    if (ok != true) return;
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

class CheckInTab extends ConsumerWidget {
  final String eventId;
  const CheckInTab({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final event = store.eventById(eventId)!;
    final user = store.user!;
    final allocs = store.allocationsForEvent(eventId);
    if (allocs.isEmpty) {
      return const EmptyState(icon: Icons.how_to_reg_outlined, title: 'Nada para check-in', subtitle: 'Al<fim-middle>oque passageiros nos ônibus primeiro.');
    }
    if (!user.canCheckIn(event)) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Check-in bloqueado',
        subtitle: 'O coordenador ainda não liberou o check-in para o seu perfil.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: allocs.length,
      itemBuilder: (context, i) {
        final a = allocs[i];
        final p = store.passengerById(a.passengerId);
        final v = store.vehicleById(a.vehicleId);
        final out = store.hasCheckIn(a.id, 'OUTBOUND');
        final back = store.hasCheckIn(a.id, 'RETURN');
        return Card(
          child: ListTile(
            title: Text(p?.name ?? 'Passageiro'),
            subtitle: Text(v?.name ?? ''),
            trailing: Wrap(
              spacing: 4,
              children: [
                _MiniCheck(
                  label: out ? 'Ida ✓' : 'Ida',
                  done: out,
                  onTap: () async {
                    final r = store.performCheckIn(a.id, 'OUTBOUND');
                    await showStoreMessage(context, r);
                  },
                ),
                _MiniCheck(
                  label: back ? 'Volta ✓' : 'Volta',
                  done: back,
                  onTap: () async {
                    final r = store.performCheckIn(a.id, 'RETURN');
                    await showStoreMessage(context, r);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniCheck extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;
  const _MiniCheck({required this.label, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: done ? null : onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 36),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(label),
    );
  }
}

class HistoryTab extends ConsumerWidget {
  final String eventId;
  const HistoryTab({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(localStoreProvider).activityForEvent(eventId);
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.history, title: 'Sem histórico ainda');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = items[i];
        return ListTile(
          title: Text(a.message),
          subtitle: Text('${a.actorName} • ${AppFormatters.date(a.at)}'),
        );
      },
    );
  }
}

class SettingsTab extends ConsumerWidget {
  final TransportEvent event;
  const SettingsTab({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SwitchListTile(
          title: const Text('Capitão pode fazer check-in'),
          value: event.captainCheckinEnabled,
          onChanged: (v) => store.updateEvent(event.copyWith(captainCheckinEnabled: v)),
        ),
        SwitchListTile(
          title: const Text('Ajudante do capitão pode fazer check-in'),
          value: event.helperCheckinEnabled,
          onChanged: (v) => store.updateEvent(event.copyWith(helperCheckinEnabled: v)),
        ),
        const Divider(),
        ListTile(
          title: const Text('Restaurar dados de demonstração'),
          subtitle: const Text('Apaga o que está neste aparelho e recarrega o exemplo.'),
          trailing: const Icon(Icons.restore),
          onTap: () async {
            final ok = await confirmDialog(context, 'Isso substitui todos os dados locais pelo exemplo.');
            if (ok) await store.resetDemo();
          },
        ),
      ],
    );
  }
}

Future<void> showVehicleSheet(
  BuildContext context,
  WidgetRef ref,
  String eventId, {
  Vehicle? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final physical = TextEditingController(text: '${existing?.physicalCapacity ?? 46}');
  final local = TextEditingController(text: '${existing?.localCapacity ?? 30}');
  var type = existing?.type ?? VehicleType.bus;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existing == null ? 'Novo veículo' : 'Editar veículo', style: Theme.of(ctx).textTheme.titleMedium),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
                DropdownButtonFormField<VehicleType>(
                  value: type,
                  items: VehicleType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setLocal(() => type = v ?? type),
                ),
                TextField(
                  controller: physical,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacidade física'),
                ),
                TextField(
                  controller: local,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limite local da congregação'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final store = ref.read(localStoreProvider);
                    final result = existing == null
                        ? store.addVehicle(
                            eventId: eventId,
                            name: name.text,
                            type: type,
                            physicalCapacity: int.tryParse(physical.text) ?? 0,
                            localCapacity: int.tryParse(local.text) ?? 0,
                          )
                        : store.updateVehicle(
                            Vehicle(
                              id: existing.id,
                              eventId: eventId,
                              name: name.text,
                              type: type,
                              physicalCapacity: int.tryParse(physical.text) ?? 0,
                              localCapacity: int.tryParse(local.text) ?? 0,
                            ),
                          );
                    Navigator.pop(ctx);
                    if (context.mounted) await showStoreMessage(context, result);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
