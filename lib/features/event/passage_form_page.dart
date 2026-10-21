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
    final missing = widget.isEditing &&
        _loaded &&
        store.passageById(widget.passageId!) == null;

    if (missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar passagem')),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Passagem não encontrada',
          subtitle: 'Ela pode ter sido removida ou não pertence a este evento.',
        ),
      );
    }

    final event = store.eventById(widget.eventId);
    final expectedPreview = widget.isEditing && event != null
        ? _drafts.fold<int>(0, (sum, d) {
            return sum +
                DomainCalculations.calculatePassengerDueCents(
                  selectedDaysCount: d.dayIds.length,
                  dailyFareCents: event.dailyFareCents,
                  isExempt: d.category == PassengerCategory.exempt,
                );
          })
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar passagem' : 'Nova passagem'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _buyer,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Quem paga (comprador)'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<PaymentMethod>(
            value: _method,
            decoration: const InputDecoration(labelText: 'Forma de pagamento'),
            items: PaymentMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: _saving ? null : (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.isEditing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Histórico financeiro', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Já recebido: ${AppFormatters.cents(_initialPaidCents ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (expectedPreview != null)
                      Text(
                        'Valor esperado (recalculado): ${AppFormatters.cents(expectedPreview)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'O valor já recebido não é alterado aqui. Use “Registrar pagamento” na lista para novos recebimentos.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (_existingReceiptNotes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('Comprovantes registrados:', style: Theme.of(context).textTheme.labelLarge),
                      ..._existingReceiptNotes.map(
                        (n) => Text('• $n', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _paid,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor recebido agora (R\$)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _receipt,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Comprovante (nota / referência)',
                hintText: 'Ex.: PIX 14/10 Banco X — fotos no celular depois',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Quem viaja', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _saving ? null : () => setState(() => _drafts.add(_Draft())),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Passageiro'),
              ),
            ],
          ),
          ...List.generate(_drafts.length, (i) {
            final d = _drafts[i];
            final suggestions = store.suggestPeople(d.name.text);
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Passageiro ${i + 1}', style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        if (_drafts.length > 1)
                          IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                      _drafts.removeAt(i).dispose();
                                    }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    TextField(
                      controller: d.name,
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (suggestions.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: suggestions
                            .map(
                              (p) => ActionChip(
                                label: Text('Usar ${p.fullName}'),
                                onPressed: _saving ? null : () => _applySuggestion(i, p),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<PassengerCategory>(
                      value: d.category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: PassengerCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => d.category = v ?? d.category),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: d.documentType,
                            decoration: const InputDecoration(labelText: 'Documento'),
                            items: const ['CPF', 'RG', 'Certidão', 'Outro']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => d.documentType = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
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
                    if (d.category == PassengerCategory.exempt ||
                        d.category == PassengerCategory.minor)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nascimento'),
                        subtitle: Text(
                          d.birthDate == null
                              ? 'Obrigatório para isenção'
                              : AppFormatters.date(d.birthDate!),
                        ),
                        onTap: _saving
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: d.birthDate ?? DateTime(2018),
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) setState(() => d.birthDate = picked);
                              },
                      ),
                    if (d.category == PassengerCategory.minor ||
                        d.category == PassengerCategory.student)
                      TextField(
                        controller: d.responsible,
                        enabled: !_saving,
                        decoration: const InputDecoration(labelText: 'Responsável'),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Dias de viagem', style: Theme.of(context).textTheme.labelLarge),
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
              ),
            );
          }),
          FilledButton(
            onPressed: _saving ? null : () => _save(),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Salvar alterações' : 'Registrar passagem'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
