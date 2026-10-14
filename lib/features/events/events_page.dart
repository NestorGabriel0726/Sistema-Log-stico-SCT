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
import 'event_form_page.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final user = store.user!;
    final events = store.listEvents();
    final theme = Theme.of(context);

    return Scaffold(
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
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('Eventos'),
                  actions: [
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: () => store.signOut(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: theme.textTheme.titleMedium),
                              Text(
                                user.role.label,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (events.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nenhum evento ainda',
                      subtitle: 'Crie o primeiro congresso ou assembleia para começar a lista de ônibus.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _EventCard(
                          event: event,
                          passengers: store.passengersForEvent(event.id).length,
                          vehicles: store.vehiclesForEvent(event.id).length,
                          onTap: () => context.go('/events/${event.id}'),
                          onEdit: user.canManageEvent
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EventFormPage(existing: event)),
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
    );
  }
}

class _EventCard extends StatelessWidget {
  final TransportEvent event;
  final int passengers;
  final int vehicles;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _EventCard({
    required this.event,
    required this.passengers,
    required this.vehicles,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TagChip(label: event.kind.label),
                  const Spacer(),
                  TagChip(
                    label: event.lifecycle.label,
                    color: AppColors.success.withValues(alpha: 0.12),
                    foreground: AppColors.success,
                  ),
                  if (onEdit != null)
                    IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                ],
              ),
              Text(event.theme, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppFormatters.dateRange(event.startDate, event.endDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.groups_2_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('$passengers passageiros'),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(Icons.directions_bus_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('$vehicles veículos'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
