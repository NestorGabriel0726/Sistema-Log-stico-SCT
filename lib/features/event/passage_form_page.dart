import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/local_app_store.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class PassageFormPage extends ConsumerStatefulWidget {
  final String eventId;
  const PassageFormPage({super.key, required this.eventId});

  @override
  ConsumerState<PassageFormPage> createState() => _PassageFormPageState();
}

class _Draft {
  final name = TextEditingController();
  final document = TextEditingController();
  final responsible = TextEditingController();
  String? documentType = 'CPF';
  DateTime? birthDate;
  PassengerCategory category = PassengerCategory.adult;
  final Set<String> dayIds = {};
}

class _PassageFormPageState extends ConsumerState<PassageFormPage> {
  final _buyer = TextEditingController();
  final _paid = TextEditingController(text: '0');
  final _receipt = TextEditingController();
  PaymentMethod _method = PaymentMethod.pix;
  final _drafts = <_Draft>[_Draft()];

  @override
  void dispose() {
    _buyer.dispose();
    _paid.dispose();
    _receipt.dispose();
    for (final d in _drafts) {
      d.name.dispose();
      d.document.dispose();
      d.responsible.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool bypass = false}) async {
    final store = ref.read(localStoreProvider);
    final paid = double.tryParse(_paid.text.replaceAll(',', '.')) ?? 0;
    final notes = _receipt.text.trim().isEmpty ? <String>[] : [_receipt.text.trim()];
    final passengers = _drafts
        .map(
          (d) => PassengerDraft(
            name: d.name.text,
            documentType: d.documentType,
            documentNumber: d.document.text.trim().isEmpty ? null : d.document.text.trim(),
            birthDate: d.birthDate,
            category: d.category,
            responsibleName: d.responsible.text.trim().isEmpty ? null : d.responsible.text.trim(),
            dayIds: d.dayIds.toList(),
          ),
        )
        .toList();
    var result = store.createPassage(
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
    if (!result.ok) {
      await showStoreMessage(context, result);
      return;
    }
    if (mounted) Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Nova passagem')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(controller: _buyer, decoration: const InputDecoration(labelText: 'Quem paga (comprador)')),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<PaymentMethod>(
            value: _method,
            decoration: const InputDecoration(labelText: 'Forma de pagamento'),
            items: PaymentMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _paid,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor recebido agora (R\$)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _receipt,
            decoration: const InputDecoration(
              labelText: 'Comprovante (nota / referência)',
              hintText: 'Ex.: PIX 14/10 Banco X — fotos no celular depois',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Quem viaja', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _drafts.add(_Draft())),
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
                            onPressed: () => setState(() => _drafts.removeAt(i)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    TextField(
                      controller: d.name,
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
                                onPressed: () => _applySuggestion(i, p),
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
                      onChanged: (v) => setState(() => d.category = v ?? d.category),
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
                            onChanged: (v) => setState(() => d.documentType = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: d.document,
                            decoration: const InputDecoration(labelText: 'Número (pode ficar pendente)'),
                          ),
                        ),
                      ],
                    ),
                    if (d.category == PassengerCategory.exempt || d.category == PassengerCategory.minor)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nascimento'),
                        subtitle: Text(d.birthDate == null ? 'Obrigatório para isenção' : AppFormatters.date(d.birthDate!)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: d.birthDate ?? DateTime(2018),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => d.birthDate = picked);
                        },
                      ),
                    if (d.category == PassengerCategory.minor || d.category == PassengerCategory.student)
                      TextField(
                        controller: d.responsible,
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
                              onSelected: (sel) => setState(() {
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
          FilledButton(onPressed: () => _save(), child: const Text('Registrar passagem')),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
