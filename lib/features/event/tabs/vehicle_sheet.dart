import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import 'package:uuid/uuid.dart';

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
