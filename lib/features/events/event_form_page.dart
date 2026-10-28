import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
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
  late DateTime _end =
      widget.existing?.endDate ?? DateTime.now().add(const Duration(days: 2));
  late final _fare = TextEditingController(
    text: ((widget.existing?.dailyFareCents ?? 5000) / 100).toStringAsFixed(2),
  );
  late final _age =
      TextEditingController(text: '${widget.existing?.minimumPayingAge ?? 6}');
  DateTime? _passageDl;
  DateTime? _preDl;
  DateTime? _finalDl;
  bool _saving = false;

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
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final fare = double.tryParse(_fare.text.replaceAll(',', '.')) ?? 0;
      final cents = (fare * 100).round();
      final age = int.tryParse(_age.text) ?? 6;
      final store = ref.read(localStoreProvider);
      final existing = widget.existing;
      final result = existing == null
          ? store.createEvent(
              theme: _theme.text.trim(),
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
        if (mounted) await showStoreMessage(context, result);
        return;
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar evento' : 'Novo evento'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ─── Seção: Informações gerais ──────────────────────────────
              _SectionCard(
                title: 'Informações gerais',
                icon: Icons.info_outline_rounded,
                children: [
                  TextField(
                    controller: _theme,
                    decoration: const InputDecoration(
                      labelText: 'Tema do evento',
                      hintText: 'Ex.: "Fortalece os fracos"',
                      prefixIcon: Icon(Icons.title_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<EventKind>(
                    value: _kind,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: EventKind.values
                        .map((k) => DropdownMenuItem(
                            value: k, child: Text(k.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _kind = v ?? _kind),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Seção: Datas ──────────────────────────────────────────
              _SectionCard(
                title: 'Período do evento',
                icon: Icons.calendar_month_outlined,
                children: [
                  _DateField(
                    label: 'Data de início',
                    date: _start,
                    onPick: () async {
                      final d = await _pickDate(_start);
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DateField(
                    label: 'Data de término',
                    date: _end,
                    onPick: () async {
                      final d = await _pickDate(_end);
                      if (d != null) setState(() => _end = d);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Seção: Financeiro ─────────────────────────────────────
              _SectionCard(
                title: 'Configurações financeiras',
                icon: Icons.payments_outlined,
                children: [
                  TextField(
                    controller: _fare,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor da diária (R\$)',
                      hintText: '50,00',
                      prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Idade mínima para cobrança',
                      hintText: '6',
                      prefixIcon: Icon(Icons.child_care_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Seção: Prazos ─────────────────────────────────────────
              _SectionCard(
                title: 'Prazos operacionais',
                icon: Icons.schedule_outlined,
                children: [
                  _DeadlineField(
                    title: 'Limite para receber passagens',
                    date: _passageDl,
                    onPick: () async {
                      final d = await _pickDate(_passageDl ?? _start);
                      setState(() => _passageDl = d);
                    },
                    onClear: () => setState(() => _passageDl = null),
                  ),
                  const Divider(height: 1),
                  _DeadlineField(
                    title: 'Lista prévia ao Coord. de Transporte',
                    date: _preDl,
                    onPick: () async {
                      final d = await _pickDate(_preDl ?? _start);
                      setState(() => _preDl = d);
                    },
                    onClear: () => setState(() => _preDl = null),
                  ),
                  const Divider(height: 1),
                  _DeadlineField(
                    title: 'Lista definitiva ao Coord. de Transporte',
                    date: _finalDl,
                    onPick: () async {
                      final d = await _pickDate(_finalDl ?? _start);
                      setState(() => _finalDl = d);
                    },
                    onClear: () => setState(() => _finalDl = null),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Botão de salvar ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEdit ? 'Salvar alterações' : 'Criar evento'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes internos do formulário
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.brand)),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;

  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.canvasLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.brand),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(AppFormatters.date(date),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18,
                color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

class _DeadlineField extends StatelessWidget {
  final String title;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DeadlineField({
    required this.title,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSet = date != null;
    final now = DateTime.now();
    final isLate = isSet && now.isAfter(date!);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Icon(
        isLate
            ? Icons.warning_amber_rounded
            : Icons.event_available_outlined,
        size: 18,
        color: isLate ? AppColors.warning : cs.onSurfaceVariant,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(
        isSet ? AppFormatters.date(date!) : 'Não definido',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isLate
                  ? AppColors.warning
                  : (isSet ? AppColors.brand : cs.onSurfaceVariant),
              fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSet)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 16),
              tooltip: 'Remover prazo',
              color: cs.onSurfaceVariant,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            onPressed: onPick,
            icon: const Icon(Icons.edit_calendar_outlined, size: 16),
            tooltip: 'Definir prazo',
            color: AppColors.brand,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
