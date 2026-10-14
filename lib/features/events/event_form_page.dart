import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ui_bits.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class EventFormPage extends ConsumerStatefulWidget {
  final TransportEvent? existing;
  const EventFormPage({super.key, this.existing});

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  late final _theme = TextEditingController(text: widget.existing?.theme ?? '');
  late EventKind _kind = widget.existing?.kind ?? EventKind.regionalConvention;
  late DateTime _start = widget.existing?.startDate ?? DateTime.now();
  late DateTime _end = widget.existing?.endDate ?? DateTime.now().add(const Duration(days: 2));
  late final _fare = TextEditingController(
    text: ((widget.existing?.dailyFareCents ?? 5000) / 100).toStringAsFixed(2),
  );
  late final _age = TextEditingController(text: '${widget.existing?.minimumPayingAge ?? 6}');
  DateTime? _passageDl;
  DateTime? _preDl;
  DateTime? _finalDl;

  @override
  void initState() {
    super.initState();
    _passageDl = widget.existing?.passageDeadline;
    _preDl = widget.existing?.preliminaryListDeadline;
    _finalDl = widget.existing?.finalListDeadline;
  }

  @override
  void dispose() {
    _theme.dispose();
    _fare.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  Future<void> _save() async {
    final fare = double.tryParse(_fare.text.replaceAll(',', '.')) ?? 0;
    final cents = (fare * 100).round();
    final age = int.tryParse(_age.text) ?? 6;
    final store = ref.read(localStoreProvider);
    final existing = widget.existing;
    final result = existing == null
        ? store.createEvent(
            theme: _theme.text,
            kind: _kind,
            start: _start,
            end: _end,
            dailyFareCents: cents,
            minimumPayingAge: age,
            passageDeadline: _passageDl,
            preliminaryListDeadline: _preDl,
            finalListDeadline: _finalDl,
          )
        : store.updateEvent(
            existing.copyWith(
              theme: _theme.text.trim(),
              kind: _kind,
              startDate: _start,
              endDate: _end,
              dailyFareCents: cents,
              minimumPayingAge: age,
              passageDeadline: _passageDl,
              preliminaryListDeadline: _preDl,
              finalListDeadline: _finalDl,
              clearPassageDeadline: _passageDl == null,
              clearPreliminary: _preDl == null,
              clearFinal: _finalDl == null,
            ),
          );
    if (!result.ok) {
      await showStoreMessage(context, result);
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Novo evento' : 'Editar evento')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _theme,
            decoration: const InputDecoration(labelText: 'Tema'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<EventKind>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: EventKind.values
                .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                .toList(),
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Início'),
            subtitle: Text(AppFormatters.date(_start)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await _pickDate(_start);
              if (d != null) setState(() => _start = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fim'),
            subtitle: Text(AppFormatters.date(_end)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await _pickDate(_end);
              if (d != null) setState(() => _end = d);
            },
          ),
          TextField(
            controller: _fare,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor da passagem por dia (R\$)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Idade mínima para cobrança'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Prazos', style: Theme.of(context).textTheme.titleMedium),
          _DeadlineTile(
            title: 'Limite para receber passagens',
            date: _passageDl,
            onPick: () async {
              final d = await _pickDate(_passageDl ?? _start);
              setState(() => _passageDl = d);
            },
            onClear: () => setState(() => _passageDl = null),
          ),
          _DeadlineTile(
            title: 'Lista prévia ao Coord. de Transporte',
            date: _preDl,
            onPick: () async {
              final d = await _pickDate(_preDl ?? _start);
              setState(() => _preDl = d);
            },
            onClear: () => setState(() => _preDl = null),
          ),
          _DeadlineTile(
            title: 'Lista definitiva ao Coord. de Transporte',
            date: _finalDl,
            onPick: () async {
              final d = await _pickDate(_finalDl ?? _start);
              setState(() => _finalDl = d);
            },
            onClear: () => setState(() => _finalDl = null),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _save, child: const Text('Salvar')),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final String title;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DeadlineTile({
    required this.title,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(date == null ? 'Não definido' : AppFormatters.date(date!)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null) IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
          IconButton(onPressed: onPick, icon: const Icon(Icons.event)),
        ],
      ),
    );
  }
}
