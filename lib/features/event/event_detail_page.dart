import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_banner.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';
import 'event_tabs.dart';
import 'passage_form_page.dart';
import '../events/event_form_page.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final user = store.user!;
    final event = store.eventById(widget.eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.error_outline, title: 'Evento não encontrado'),
      );
    }

    final tabs = <_TabSpec>[
      const _TabSpec('Visão geral', Icons.space_dashboard_outlined),
      const _TabSpec('Ônibus', Icons.directions_bus_outlined),
      const _TabSpec('Passageiros', Icons.people_outline),
      if (user.canViewFinance) const _TabSpec('Passagens', Icons.receipt_long_outlined),
      const _TabSpec('Check-in', Icons.how_to_reg_outlined),
      const _TabSpec('Histórico', Icons.history),
      if (user.canManageEvent) const _TabSpec('Configurações', Icons.tune),
    ];

    if (_tab >= tabs.length) _tab = 0;

    final panes = <Widget>[
      OverviewTab(eventId: widget.eventId, showFinance: user.canViewFinance),
      VehiclesTab(eventId: widget.eventId),
      PassengersTab(eventId: widget.eventId),
      if (user.canViewFinance) PassagesTab(eventId: widget.eventId),
      CheckInTab(eventId: widget.eventId),
      HistoryTab(eventId: widget.eventId),
      if (user.canManageEvent) SettingsTab(event: event),
    ];

    return Scaffold(
      floatingActionButton: _fab(user, event, tabs[_tab].label),
      body: Column(
        children: [
          const DemoBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/events'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.theme, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${event.kind.label} • ${AppFormatters.dateRange(event.startDate, event.endDate)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Row(
              children: List.generate(tabs.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _tab == i,
                    label: Text(tabs[i].label),
                    avatar: Icon(tabs[i].icon, size: 18),
                    onSelected: (_) => setState(() => _tab = i),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: panes[_tab]),
        ],
      ),
    );
  }

  Widget? _fab(AppUser user, TransportEvent event, String tab) {
    if (!user.canEditOperations) return null;
    if (tab == 'Ônibus') {
      return FloatingActionButton.extended(
        onPressed: () => showVehicleSheet(context, ref, event.id),
        icon: const Icon(Icons.add),
        label: const Text('Veículo'),
      );
    }
    if (tab == 'Passagens') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PassageFormPage(eventId: event.id)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Passagem'),
      );
    }
    if (tab == 'Configurações' && user.canManageEvent) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventFormPage(existing: event)),
        ),
        icon: const Icon(Icons.edit),
        label: const Text('Editar evento'),
      );
    }
    return null;
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  const _TabSpec(this.label, this.icon);
}
