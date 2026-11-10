import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/domain_calculations.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
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

    var vehicles = store.vehiclesForEvent(widget.eventId);
    if (user.role == UserRole.captain || user.role == UserRole.captainHelper) {
      vehicles = vehicles.where((v) => v.id == user.assignedVehicleId).toList();
    }
    if (vehicles.isEmpty) {
      final isCaptain = user.role == UserRole.captain || user.role == UserRole.captainHelper;
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: isCaptain ? 'Nenhum veículo atribuído' : 'Nenhum veículo cadastrado',
        subtitle: isCaptain
            ? 'Você ainda não possui veículo designado para realizar o check-in neste evento.'
            : 'Adicione ônibus na aba Ônibus para organizar os embarques.',
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

