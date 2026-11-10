import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/domain_calculations.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
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
    if (store.user?.role == UserRole.captain || store.user?.role == UserRole.captainHelper) {
      final myVehiclePaxIds = store
          .allocationsForEvent(widget.eventId, activeOnly: false)
          .where((a) => a.vehicleId == store.user?.assignedVehicleId)
          .map((a) => a.passengerId)
          .toSet();
      list = list.where((p) => myVehiclePaxIds.contains(p.id)).toList();
    }

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

