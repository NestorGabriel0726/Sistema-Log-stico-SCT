import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/domain_calculations.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/local_app_store.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class PassageFormPage extends ConsumerStatefulWidget {
  final String eventId;
  final String? passageId;

  const PassageFormPage({
    super.key,
    required this.eventId,
    this.passageId,
  });

  bool get isEditing => passageId != null;

  @override
  ConsumerState<PassageFormPage> createState() => _PassageFormPageState();
}

class _Draft {
  String? id;
  final name = TextEditingController();
  final document = TextEditingController();
  final responsible = TextEditingController();
  String? documentType = 'CPF';
  DateTime? birthDate;
  PassengerCategory category = PassengerCategory.adult;
  final Set<String> dayIds = {};

  void dispose() {
    name.dispose();
    document.dispose();
    responsible.dispose();
  }
}

class _PassageFormPageState extends ConsumerState<PassageFormPage> {
  final _buyer = TextEditingController();
  final _paid = TextEditingController(text: '0');
  final _receipt = TextEditingController();
  PaymentMethod _method = PaymentMethod.pix;
  final _drafts = <_Draft>[];
  bool _saving = false;
  bool _loaded = false;
  int? _initialPaidCents;
  List<String> _existingReceiptNotes = const [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExisting();
    } else {
      _drafts.add(_Draft());
    }
    _loaded = true;
  }

  void _loadExisting() {
    final store = ref.read(localStoreProvider);
    final passage = store.passageById(widget.passageId!);
    if (passage == null || passage.eventId != widget.eventId) {
      return;
    }
    _buyer.text = passage.buyerName;
    _method = passage.paymentMethod;
    _initialPaidCents = passage.paidCents;
    _existingReceiptNotes = List<String>.from(passage.receiptNotes);
    _paid.text = (passage.paidCents / 100).toStringAsFixed(2);
    for (final id in passage.passengerIds) {
      final p = store.passengerById(id);
      if (p == null) continue;
      final d = _Draft()
        ..id = p.id
        ..documentType = p.documentType ?? 'CPF'
        ..birthDate = p.birthDate
        ..category = p.category;
      d.name.text = p.name;
      d.document.text = p.documentNumber ?? '';
      d.responsible.text = p.responsibleName ?? '';
      d.dayIds.addAll(p.dayIds);
      _drafts.add(d);
    }
    if (_drafts.isEmpty) {
      _drafts.add(_Draft());
    }
  }

  @override
  void dispose() {
    _buyer.dispose();
    _paid.dispose();
    _receipt.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  List<PassengerDraft> _buildDrafts() {
    return _drafts
        .map(
          (d) => PassengerDraft(
            id: d.id,
            name: d.name.text,
            documentType: d.documentType,
            documentNumber: d.document.text.trim().isEmpty ? null : d.document.text.trim(),
            birthDate: d.birthDate,
            category: d.category,
            responsibleName:
                d.responsible.text.trim().isEmpty ? null : d.responsible.text.trim(),
            dayIds: d.dayIds.toList(),
          ),
        )
        .toList();
  }

  Future<void> _save({bool bypass = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = ref.read(localStoreProvider);
    try {
      final passengers = _buildDrafts();
      late StoreResult result;
      if (widget.isEditing) {
        result = store.updatePassage(
          passageId: widget.passageId!,
          eventId: widget.eventId,
          buyerName: _buyer.text,
          method: _method,
          passengers: passengers,
        );
      } else {
        final paid = double.tryParse(_paid.text.replaceAll(',', '.')) ?? 0;
        final notes = _receipt.text.trim().isEmpty ? <String>[] : [_receipt.text.trim()];
        result = store.createPassage(
          eventId: widget.eventId,
          buyerName: _buyer.text,
          paidCents: (paid * 100).round(),
          method: _method,
          passengers: passengers,
          receiptNotes: notes,
          confirmBypass: bypass,
        );
        if (result.needsConfirm) {
          final ok = await confirmDialog(context, result.message);
          if (ok) {
            result = store.createPassage(
              eventId: widget.eventId,
              buyerName: _buyer.text,
              paidCents: (paid * 100).round(),
              method: _method,
              passengers: passengers,
              receiptNotes: notes,
              confirmBypass: true,
            );
          } else {
            return;
          }
        }
      }

      if (!result.ok) {
        if (mounted) await showStoreMessage(context, result);
        return;
      }

      await store.flushPersist();
      if (!mounted) return;
      if (store.lastPersistError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(store.lastPersistError!)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Passagem atualizada.' : 'Passagem registrada.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applySuggestion(int index, PersonMemory person) {
    final d = _drafts[index];
    d.name.text = person.fullName;
    d.documentType = person.documentType ?? d.documentType;
    d.document.text = person.documentNumber ?? '';
    d.birthDate = person.birthDate;
    d.responsible.text = person.responsibleName ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(localStoreProvider);
    final days = store.daysForEvent(widget.eventId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final missing = widget.isEditing &&
        _loaded &&
        store.passageById(widget.passageId!) == null;

    if (missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar passagem')),
        body: const Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Passagem não encontrada',
            subtitle: 'Ela pode ter sido removida ou não pertence a este evento.',
          ),
        ),
      );
    }

    final event = store.eventById(widget.eventId);
    final expectedPreview = event != null
        ? _drafts.fold<int>(0, (sum, d) {
            final isExempt = d.birthDate != null &&
                DomainCalculations.isExemptByAge(
                  birthDate: d.birthDate!,
                  eventDate: event.startDate,
                  minimumPayingAge: event.minimumPayingAge,
                );
            return sum +
                DomainCalculations.calculatePassengerDueCents(
                  selectedDaysCount: d.dayIds.length,
                  dailyFareCents: event.dailyFareCents,
                  isExempt: isExempt,
                );
          })
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar passagem' : 'Nova passagem'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            children: [
              // Seção 1: Dados do Pagador
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Dados do Pagador',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _buyer,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Quem paga (comprador)',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<PaymentMethod>(
                      value: _method,
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
                      onChanged: _saving ? null : (v) => setState(() => _method = v ?? _method),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Seção 2: Resumo Financeiro & Pagamentos
              if (widget.isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Histórico financeiro',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Já recebido',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: AppColors.success),
                                ),
                                Text(
                                  AppFormatters.cents(_initialPaidCents ?? 0),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (expectedPreview != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceElevatedDark
                                    : AppColors.canvasLight,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor esperado (recalculado)',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  Text(
                                    AppFormatters.cents(expectedPreview),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'O valor já recebido não é alterado aqui. Use “Registrar pagamento” na lista para novos recebimentos.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (_existingReceiptNotes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Comprovantes registrados:',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        ..._existingReceiptNotes.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(n, style: theme.textTheme.bodySmall),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Pagamento Inicial',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _paid,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor recebido agora (R\$)',
                          prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _receipt,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Comprovante (nota / referência)',
                          hintText: 'Ex.: PIX 14/10 Banco X — fotos no celular depois',
                          prefixIcon: Icon(Icons.receipt_long_outlined, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Seção 3: Passageiros que Viajam
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Quem viaja',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_drafts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : () => setState(() => _drafts.add(_Draft())),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Passageiro'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              ...List.generate(_drafts.length, (i) {
                final d = _drafts[i];
                final suggestions = store.suggestPeople(d.name.text);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Passageiro ${i + 1}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (_drafts.length > 1)
                            IconButton(
                              tooltip: 'Remover passageiro',
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _drafts.removeAt(i).dispose();
                                      }),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: d.name,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          children: suggestions
                              .map(
                                (p) => ActionChip(
                                  avatar: const Icon(Icons.history_rounded, size: 16),
                                  label: Text('Usar ${p.fullName}'),
                                  onPressed: _saving ? null : () => _applySuggestion(i, p),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      if (d.category == PassengerCategory.exempt) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Este passageiro foi cadastrado anteriormente como Isento. '
                                  'A isenção agora é calculada automaticamente pela data de nascimento. '
                                  'Selecione a categoria real abaixo.',
                                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      DropdownButtonFormField<PassengerCategory>(
                        value: d.category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: [
                          if (d.category == PassengerCategory.exempt)
                            const DropdownMenuItem(
                              value: PassengerCategory.exempt,
                              child: Text('Isento (legado)'),
                            ),
                          ...PassengerCategory.values
                              .where((c) => c != PassengerCategory.exempt)
                              .map((c) => DropdownMenuItem(value: c, child: Text(c.label))),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => d.category = v ?? d.category),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: d.documentType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo Doc.',
                              ),
                              items: const ['CPF', 'RG', 'Certidão', 'Outro']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: _saving
                                  ? null
                                  : (v) => setState(() => d.documentType = v),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: d.document,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Número (pode ficar pendente)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          onTap: _saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: d.birthDate ?? DateTime(2018),
                                    firstDate: DateTime(1920),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => d.birthDate = picked);
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Data de Nascimento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(
                                        d.birthDate == null
                                            ? 'Toque para informar data de nascimento'
                                            : AppFormatters.date(d.birthDate!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: d.birthDate == null ? cs.onSurfaceVariant : cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (d.birthDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    tooltip: 'Limpar data',
                                    onPressed: _saving ? null : () => setState(() => d.birthDate = null),
                                  )
                                else
                                  const Icon(Icons.calendar_today_outlined, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (event != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Builder(
                          builder: (context) {
                            final msg = DomainCalculations.ageEligibilityMessage(
                              birthDate: d.birthDate,
                              eventDate: event.startDate,
                              minimumPayingAge: event.minimumPayingAge,
                              eventTheme: event.theme,
                            );
                            final isExempt = d.birthDate != null &&
                                DomainCalculations.isExemptByAge(
                                  birthDate: d.birthDate!,
                                  eventDate: event.startDate,
                                  minimumPayingAge: event.minimumPayingAge,
                                );
                            final bannerColor = d.birthDate == null
                                ? cs.onSurfaceVariant
                                : (isExempt ? AppColors.success : AppColors.primary);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: bannerColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    d.birthDate == null
                                        ? Icons.info_outline
                                        : (isExempt ? Icons.check_circle_outline : Icons.monetization_on_outlined),
                                    size: 16,
                                    color: bannerColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      msg,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                        color: bannerColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      if (d.category == PassengerCategory.minor ||
                          d.category == PassengerCategory.student) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: d.responsible,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Responsável',
                            prefixIcon: Icon(Icons.supervisor_account_outlined, size: 20),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Dias de viagem',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 8,
                        children: days
                            .map(
                              (day) => FilterChip(
                                label: Text(day.label),
                                selected: d.dayIds.contains(day.id),
                                onSelected: _saving
                                    ? null
                                    : (sel) => setState(() {
                                          if (sel) {
                                            d.dayIds.add(day.id);
                                          } else {
                                            d.dayIds.remove(day.id);
                                          }
                                        }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isEditing
                              ? 'Salvar alterações'
                              : 'Registrar passagem'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
