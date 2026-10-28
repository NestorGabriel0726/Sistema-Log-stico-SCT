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
import 'event_form_page.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final user = store.user!;
    final events = store.listEvents();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);
    final themeIcon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ─── AppBar ────────────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  shadowColor: isDark
                      ? AppColors.borderDark.withValues(alpha: 0.5)
                      : AppColors.borderLight.withValues(alpha: 0.5),
                  title: const Text('Eventos'),
                  actions: [
                    IconButton(
                      tooltip: 'Alternar tema',
                      icon: Icon(themeIcon, size: 20),
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),

                // ─── Header de usuário ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.brand.withValues(alpha: 0.1),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: theme.textTheme.titleSmall),
                              Text(
                                user.role.label,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => store.signOut(),
                          icon: const Icon(Icons.logout_outlined, size: 16),
                          label: const Text('Sair'),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Divisor ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),

                // ─── Padding + conteúdo ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: events.isEmpty
                      ? const SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'Nenhum evento ainda',
                            subtitle:
                                'Crie o primeiro congresso ou assembleia para começar a lista de ônibus.',
                          ),
                        )
                      : SliverList.separated(
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _EventRow(
                              event: event,
                              passengers:
                                  store.passengersForEvent(event.id).length,
                              vehicles:
                                  store.vehiclesForEvent(event.id).length,
                              passages:
                                  store.passagesForEvent(event.id).length,
                              onTap: () => context.go('/events/${event.id}'),
                              onEdit: user.canManageEvent
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                EventFormPage(existing: event)),
                                      )
                                  : null,
                            );
                          },
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: user.canManageEvent
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventFormPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Novo evento'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EventRow — linha de evento na listagem
// ─────────────────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final TransportEvent event;
  final int passengers;
  final int vehicles;
  final int passages;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _EventRow({
    required this.event,
    required this.passengers,
    required this.vehicles,
    required this.passages,
    required this.onTap,
    this.onEdit,
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: tipo + lifecycle + ações
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusChip(
                          label: event.kind.label,
                          background:
                              isDark ? AppColors.infoBgDark : AppColors.infoBg,
                          foreground: AppColors.info,
                          icon: Icons.event_outlined,
                        ),
                        StatusChip.eventLifecycle(event.lifecycle),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        Tooltip(
                          message: 'Editar evento',
                          child: IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            padding: const EdgeInsets.all(6),
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      Tooltip(
                        message: 'Abrir evento',
                        child: IconButton(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          padding: const EdgeInsets.all(6),
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Linha 2: tema
              Text(
                event.theme.isEmpty ? '(sem tema)' : event.theme,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Linha 3: datas
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppFormatters.dateRange(event.startDate, event.endDate),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Linha 4: estatísticas
              Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                        icon: Icons.people_outline,
                        value: '$passengers',
                        label: 'passag.'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _Stat(
                        icon: Icons.directions_bus_outlined,
                        value: '$vehicles',
                        label: 'veíc.'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _Stat(
                        icon: Icons.receipt_long_outlined,
                        value: '$passages',
                        label: 'passagens'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' $label',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
