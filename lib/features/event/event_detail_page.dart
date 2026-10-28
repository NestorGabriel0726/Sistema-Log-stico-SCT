import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
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

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializa com número máximo de tabs possível; ajustado no build
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final user = store.user!;
    final event = store.eventById(widget.eventId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final themeIcon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };

    if (event == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/events'))),
        body: const EmptyState(icon: Icons.error_outline, title: 'Evento não encontrado'),
      );
    }

    final tabs = <_TabSpec>[
      const _TabSpec('Visão geral', Icons.space_dashboard_outlined,
          Icons.space_dashboard_rounded),
      const _TabSpec('Ônibus', Icons.directions_bus_outlined,
          Icons.directions_bus_rounded),
      const _TabSpec('Passageiros', Icons.people_outline, Icons.people_rounded),
      if (user.canViewFinance)
        const _TabSpec('Passagens', Icons.receipt_long_outlined,
            Icons.receipt_long_rounded),
      const _TabSpec('Check-in', Icons.how_to_reg_outlined,
          Icons.how_to_reg_rounded),
      const _TabSpec('Histórico', Icons.history_outlined, Icons.history),
      if (user.canManageEvent)
        const _TabSpec('Configurações', Icons.tune_outlined, Icons.tune),
    ];

    if (_tab >= tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tab = 0);
      });
    }

    // Recria o TabController se o número de abas mudou
    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: tabs.length,
        vsync: this,
        initialIndex: _tab.clamp(0, tabs.length - 1),
      );
      _tabController.addListener(() {
        if (mounted) setState(() => _tab = _tabController.index);
      });
    }

    final panes = <Widget>[
      OverviewTab(eventId: widget.eventId, showFinance: user.canViewFinance),
      VehiclesTab(eventId: widget.eventId),
      PassengersTab(eventId: widget.eventId),
      if (user.canViewFinance) PassagesTab(eventId: widget.eventId),
      CheckInTab(eventId: widget.eventId),
      HistoryTab(eventId: widget.eventId),
      if (user.canManageEvent) SettingsTab(event: event),
    ];

    final currentTab = _tab.clamp(0, tabs.length - 1);
    final currentLabel = tabs[currentTab].label;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      floatingActionButton: _fab(context, ref, user, event, currentLabel),
      body: Column(
        children: [
          const DemoBanner(),
          // ─── Cabeçalho do evento ──────────────────────────────────────────
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Column(
              children: [
                // Barra de navegação superior
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs, AppSpacing.sm, AppSpacing.sm, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/events'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Voltar aos eventos',
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Breadcrumb
                              Row(
                                children: [
                                  Text(
                                    'Eventos',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant),
                                  ),
                                  Icon(Icons.chevron_right,
                                      size: 14, color: cs.onSurfaceVariant),
                                  Flexible(
                                    child: Text(
                                      event.kind.label,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.theme.isEmpty ? '(sem tema)' : event.theme,
                                style: theme.textTheme.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  StatusChip.eventLifecycle(event.lifecycle),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 12, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppFormatters.dateRange(
                                            event.startDate, event.endDate),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Toggle de tema
                      IconButton(
                        tooltip: 'Alternar tema',
                        icon: Icon(themeIcon, size: 20),
                        color: cs.onSurfaceVariant,
                        onPressed: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // ─── TabBar ──────────────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  indicatorColor: AppColors.brand,
                  indicatorWeight: 2,
                  labelColor: AppColors.brand,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: theme.textTheme.labelMedium,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  tabs: tabs
                      .map(
                        (t) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tab == tabs.indexOf(t) ? t.selectedIcon : t.icon,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(t.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onTap: (i) => setState(() => _tab = i),
                ),
              ],
            ),
          ),
          // ─── Conteúdo da aba ───────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: currentTab,
              children: panes,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _fab(BuildContext context, WidgetRef ref, AppUser user,
      TransportEvent event, String tab) {
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
          MaterialPageRoute(
              builder: (_) => PassageFormPage(eventId: event.id)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Passagem'),
      );
    }
    if (tab == 'Configurações' && user.canManageEvent) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventFormPage(existing: event)),
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
  final IconData selectedIcon;
  const _TabSpec(this.label, this.icon, this.selectedIcon);
}
