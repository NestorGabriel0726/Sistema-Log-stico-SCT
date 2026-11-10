import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
import '../passage_form_page.dart';

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
    PaymentMethod selectedMethod = PaymentMethod.pix;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            title: Text('Pagamento — ${group.buyerName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Já recebido: ${AppFormatters.cents(group.paidCents)}',
                        style: theme.textTheme.bodySmall
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
                // Seleção de método de pagamento
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pagamento',
                    prefixIcon: Icon(Icons.payment_outlined, size: 20),
                  ),
                  items: PaymentMethod.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedMethod = v ?? selectedMethod),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: 'Comprovante / nota',
                    hintText: selectedMethod == PaymentMethod.pix
                        ? 'Ex.: PIX 14/10'
                        : 'Ex.: dinheiro entregue em maos',
                    prefixIcon: const Icon(Icons.note_outlined, size: 20),
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
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final reais = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    final store = ref.read(localStoreProvider);
    final result = store.addPayment(
      passageId: group.id,
      extraCents: (reais * 100).round(),
      method: selectedMethod,
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

