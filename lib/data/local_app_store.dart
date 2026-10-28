import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/formatters.dart';
import '../core/utils/domain_calculations.dart';
import '../domain/models.dart';
import 'seed_data.dart';

class LocalAppStore extends ChangeNotifier {
  static const _prefsKey = 'sct_local_state_v2';
  static const _prefsBackupKey = 'sct_local_state_v2_backup';
  final _uuid = const Uuid();

  AppUser? _user;
  List<TransportEvent> _events = [];
  List<EventDay> _days = [];
  List<Vehicle> _vehicles = [];
  List<Passenger> _passengers = [];
  List<Allocation> _allocations = [];
  List<PassageGroup> _passages = [];
  List<CheckInRecord> _checkIns = [];
  List<PersonMemory> _people = [];
  List<ActivityEntry> _activity = [];
  bool _hydrated = false;
  String? _lastPersistError;
  bool _persistenceBlocked = false;
  bool _storageCorrupted = false;
  final List<String> _loadErrors = [];
  Future<void> _persistChain = Future<void>.value();

  /// Quando true, a próxima gravação falha de propósito (somente testes).
  @visibleForTesting
  bool failNextPersist = false;

  LocalAppStore() {
    applySeed();
  }

  AppUser? get user => _user;
  bool get hydrated => _hydrated;
  String? get lastPersistError => _lastPersistError;
  bool get persistenceBlocked => _persistenceBlocked;
  bool get storageCorrupted => _storageCorrupted;
  List<String> get loadErrors => List.unmodifiable(_loadErrors);

  void clearPersistError() {
    if (_lastPersistError == null) return;
    _lastPersistError = null;
    notifyListeners();
  }

  /// Desbloqueia explicitamente a persistência (por decisão intencional do operador).
  void unblockPersistence() {
    _persistenceBlocked = false;
    _storageCorrupted = false;
    _loadErrors.clear();
    _lastPersistError = null;
    notifyListeners();
  }

  void applySeed() {
    _events = [SeedData.demoEvent];
    _days = List.from(SeedData.days);
    _vehicles = List.from(SeedData.vehicles);
    _passengers = List.from(SeedData.passengers);
    _allocations = List.from(SeedData.allocations);
    _passages = List.from(SeedData.passages);
    _checkIns = [];
    _people = List.from(SeedData.people);
    _activity = List.from(SeedData.activities);
  }

  void _clearState() {
    _user = null;
    _events = [];
    _days = [];
    _vehicles = [];
    _passengers = [];
    _allocations = [];
    _passages = [];
    _checkIns = [];
    _people = [];
    _activity = [];
  }

  Future<void> hydrate() async {
    _loadErrors.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        dynamic decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (e, st) {
          debugPrint('LocalAppStore.hydrate: JSON corrompido: $e\n$st');
          _storageCorrupted = true;
          _persistenceBlocked = true;
          _loadErrors.add('JSON corrompido: $e');
          await prefs.setString(_prefsBackupKey, raw);
          _clearState();
          _lastPersistError =
              'Falha ao ler dados salvos (JSON corrompido). '
              'A gravação automática foi bloqueada para proteger o arquivo salvo.';
          _hydrated = true;
          notifyListeners();
          return;
        }

        if (decoded is! Map<String, dynamic>) {
          _storageCorrupted = true;
          _persistenceBlocked = true;
          _loadErrors.add('Estrutura inválida: raiz do JSON não é um objeto');
          await prefs.setString(_prefsBackupKey, raw);
          _clearState();
          _lastPersistError =
              'Formato de dados incompatível. A gravação foi bloqueada para proteger o arquivo salvo.';
          _hydrated = true;
          notifyListeners();
          return;
        }

        final errors = _fromMap(decoded);
        if (errors.isNotEmpty) {
          _loadErrors.addAll(errors);
          _storageCorrupted = true;
          _persistenceBlocked = true;
          await prefs.setString(_prefsBackupKey, raw);
          _lastPersistError =
              'Atenção: foram encontrados dados corrompidos no arquivo salvo. '
              'A gravação foi bloqueada para evitar descarte silencioso de registros.';
        } else {
          _storageCorrupted = false;
          _persistenceBlocked = false;
          _lastPersistError = null;
        }
      }
    } catch (e, st) {
      debugPrint('LocalAppStore.hydrate falhou: $e\n$st');
      _storageCorrupted = true;
      _persistenceBlocked = true;
      _loadErrors.add('Falha inesperada no hydrate: $e');
      _lastPersistError =
          'Não foi possível carregar os dados salvos neste aparelho. '
          'A gravação foi bloqueada para segurança.';
    }
    _hydrated = true;
    notifyListeners();
  }

  /// Aguarda a fila de gravações pendentes (útil em testes e ao sair da tela).
  Future<void> flushPersist() => _persistChain;

  Future<void> _persist() async {
    if (_persistenceBlocked) {
      throw StateError(
        'Gravação em disco bloqueada para proteger dados salvos que falharam ao carregar.',
      );
    }
    if (failNextPersist) {
      failNextPersist = false;
      throw StateError('Falha simulada de persistência');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_toMap()));
  }

  void _changed() {
    notifyListeners();
    _persistChain = _persistChain.then((_) async {
      try {
        await _persist();
        if (_lastPersistError != null) {
          _lastPersistError = null;
          notifyListeners();
        }
      } catch (e, st) {
        debugPrint('LocalAppStore.persist falhou: $e\n$st');
        _lastPersistError = _persistenceBlocked
            ? 'Gravação bloqueada: dados corrompidos detectados no aparelho.'
            : 'Não foi possível salvar as alterações neste aparelho. Tente de novo.';
        notifyListeners();
      }
    });
  }

  Future<void> resetDemo() async {
    _persistenceBlocked = false;
    _storageCorrupted = false;
    _loadErrors.clear();
    _lastPersistError = null;
    applySeed();
    _changed();
    await flushPersist();
  }

  void signIn({
    required String name,
    required UserRole role,
    String? assignedVehicleId,
  }) {
    _user = AppUser(
      id: 'local-user',
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@demo.local',
      role: role,
      assignedVehicleId: assignedVehicleId,
    );
    _changed();
  }

  void signOut() {
    _user = null;
    _changed();
  }

  List<TransportEvent> listEvents() => List.unmodifiable(_events);

  TransportEvent? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<EventDay> daysForEvent(String eventId) =>
      _days.where((d) => d.eventId == eventId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Vehicle> vehiclesForEvent(String eventId) =>
      _vehicles.where((v) => v.eventId == eventId).toList();

  List<Passenger> passengersForEvent(String eventId) =>
      _passengers.where((p) => p.eventId == eventId).toList();

  List<PassageGroup> passagesForEvent(String eventId) =>
      _passages.where((p) => p.eventId == eventId).toList();

  List<Allocation> allocationsForEvent(String eventId, {bool activeOnly = true}) {
    final ids = passengersForEvent(eventId).map((p) => p.id).toSet();
    return _allocations
        .where((a) => ids.contains(a.passengerId) && (!activeOnly || a.isActive))
        .toList();
  }

  List<Allocation> allocationsForVehicleDay(String vehicleId, String dayId) {
    return _allocations
        .where((a) => a.vehicleId == vehicleId && a.dayId == dayId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  List<Passenger> unallocatedOnDay(String eventId, String dayId) {
    final allocated = _allocations
        .where((a) => a.dayId == dayId && a.isActive)
        .map((a) => a.passengerId)
        .toSet();
    return passengersForEvent(eventId)
        .where((p) => p.dayIds.contains(dayId) && !allocated.contains(p.id))
        .toList();
  }

  Passenger? passengerById(String id) {
    for (final p in _passengers) {
      if (p.id == id) return p;
    }
    return null;
  }

  Vehicle? vehicleById(String id) {
    for (final v in _vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  EventDay? dayById(String id) {
    for (final d in _days) {
      if (d.id == id) return d;
    }
    return null;
  }

  PassageGroup? passageById(String id) {
    for (final p in _passages) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<VehicleDayStats> vehicleDayStats(String eventId) {
    final result = <VehicleDayStats>[];
    for (final vehicle in vehiclesForEvent(eventId)) {
      for (final day in daysForEvent(eventId)) {
        final occupied = _allocations
            .where((a) => a.vehicleId == vehicle.id && a.dayId == day.id && a.isActive)
            .length;
        result.add(
          VehicleDayStats(
            vehicleId: vehicle.id,
            vehicleName: vehicle.name,
            dayId: day.id,
            dayLabel: day.label,
            occupied: occupied,
            capacity: vehicle.localCapacity,
          ),
        );
      }
    }
    return result;
  }

  List<DayCount> passengersPerDay(String eventId) {
    return daysForEvent(eventId).map((d) {
      final count = passengersForEvent(eventId).where((p) => p.dayIds.contains(d.id)).length;
      return DayCount(dayId: d.id, label: d.label, passengers: count);
    }).toList();
  }

  int expectedCentsForPassenger(Passenger p, TransportEvent event) {
    return DomainCalculations.calculatePassengerDueCents(
      selectedDaysCount: p.dayIds.length,
      dailyFareCents: event.dailyFareCents,
      isExempt: p.isExempt,
    );
  }

  int expectedCentsForPassage(PassageGroup group) {
    final event = eventById(group.eventId);
    if (event == null) return 0;
    var total = 0;
    for (final id in group.passengerIds) {
      final p = passengerById(id);
      if (p == null) continue;
      total += expectedCentsForPassenger(p, event);
    }
    return total;
  }

  FinancialStatus financialStatus(PassageGroup group) {
    final expected = expectedCentsForPassage(group);
    final code = DomainCalculations.calculateFinancialStatus(
      expectedCents: expected,
      paidCents: group.paidCents,
    );
    return AppFormatters.fromCode(code);
  }

  FinanceSummary financeSummary(String eventId) {
    final event = eventById(eventId);
    if (event == null) {
      return const FinanceSummary(expectedCents: 0, paidCents: 0);
    }
    var expected = 0;
    for (final p in passengersForEvent(eventId)) {
      expected += expectedCentsForPassenger(p, event);
    }
    final paid = _passages
        .where((g) => g.eventId == eventId)
        .fold<int>(0, (s, g) => s + g.paidCents);
    return FinanceSummary(expectedCents: expected, paidCents: paid);
  }

  /// Calcula os recebimentos separados por método de pagamento.
  ///
  /// - [pixCents]: soma dos [PaymentRecord] com método PIX.
  /// - [cashCents]: soma dos [PaymentRecord] com método Espécie.
  /// - [unknownCents]: `paidCents` de passagens sem nenhum [PaymentRecord]
  ///   (registros anteriores à funcionalidade de rastreamento por método).
  FinanceSummaryByMethod financeSummaryByMethod(String eventId) {
    var pix = 0;
    var cash = 0;
    var unknown = 0;
    for (final g in _passages.where((p) => p.eventId == eventId)) {
      if (g.paymentRecords.isEmpty) {
        // Passagem antiga — contabiliza paidCents sem método rastreado.
        unknown += g.paidCents;
      } else {
        for (final r in g.paymentRecords) {
          if (r.method == PaymentMethod.pix) {
            pix += r.amountCents;
          } else {
            cash += r.amountCents;
          }
        }
      }
    }
    return FinanceSummaryByMethod(
      pixCents: pix,
      cashCents: cash,
      unknownCents: unknown,
    );
  }

  List<ActivityEntry> activityForEvent(String eventId) =>
      _activity.where((a) => a.eventId == eventId).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  List<PersonMemory> suggestPeople(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return _people.where((p) => p.fullName.toLowerCase().contains(q)).toList();
  }

  String? validateExemption({
    required PassengerCategory category,
    required DateTime? birthDate,
    required TransportEvent event,
  }) {
    if (category != PassengerCategory.exempt) return null;
    if (birthDate == null) {
      return 'Informe a data de nascimento para isenção.';
    }
    if (!DomainCalculations.isExemptByAge(
      birthDate: birthDate,
      eventDate: event.startDate,
      minimumPayingAge: event.minimumPayingAge,
    )) {
      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birthDate,
        targetDate: event.startDate,
      );
      return 'Na data do evento a criança terá $age anos. Cadastre como pagante (idade mínima ${event.minimumPayingAge}).';
    }
    return null;
  }

  StoreResult createEvent({
    required String theme,
    required EventKind kind,
    required DateTime start,
    required DateTime end,
    required int dailyFareCents,
    int minimumPayingAge = 6,
    DateTime? passageDeadline,
    DateTime? preliminaryListDeadline,
    DateTime? finalListDeadline,
  }) {
    if (theme.trim().isEmpty) return const StoreResult.error('Informe o tema.');
    if (end.isBefore(start)) return const StoreResult.error('Data final inválida.');
    final id = _uuid.v4();
    _events.add(
      TransportEvent(
        id: id,
        theme: theme.trim(),
        kind: kind,
        lifecycle: EventLifecycle.open,
        startDate: start,
        endDate: end,
        dailyFareCents: dailyFareCents,
        minimumPayingAge: minimumPayingAge,
        passageDeadline: passageDeadline,
        preliminaryListDeadline: preliminaryListDeadline,
        finalListDeadline: finalListDeadline,
      ),
    );
    final daysResult = _syncEventDays(id, start, end);
    if (!daysResult.ok) {
      _events.removeWhere((e) => e.id == id);
      return daysResult;
    }
    _log(id, 'Evento "$theme" criado.');
    _changed();
    return StoreResult.ok(id);
  }

  StoreResult updateEvent(TransportEvent updated) {
    final i = _events.indexWhere((e) => e.id == updated.id);
    if (i < 0) return const StoreResult.error('Evento não encontrado.');
    final old = _events[i];
    if (old.startDate != updated.startDate || old.endDate != updated.endDate) {
      final daysResult = _syncEventDays(updated.id, updated.startDate, updated.endDate);
      if (!daysResult.ok) return daysResult;
    }
    _events[i] = updated;
    _log(updated.id, 'Configurações do evento atualizadas.');
    _changed();
    return const StoreResult.ok();
  }

  /// Mantém IDs de dias cujas datas continuam no intervalo; só cria IDs novos
  /// para datas novas; bloqueia remoção de dias com dependências.
  StoreResult _syncEventDays(String eventId, DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return const StoreResult.error('Data final inválida.');
    }

    final existing = _days.where((d) => d.eventId == eventId).toList();
    final existingByDate = <DateTime, EventDay>{
      for (final d in existing) _dateOnly(d.date): d,
    };

    final desiredDates = <DateTime>[];
    var cursor = _dateOnly(start);
    final last = _dateOnly(end);
    while (!cursor.isAfter(last)) {
      desiredDates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    final desiredSet = desiredDates.toSet();

    for (final day in existing) {
      final key = _dateOnly(day.date);
      if (desiredSet.contains(key)) continue;
      final deps = _describeDayDependencies(eventId, day.id);
      if (deps != null) {
        return StoreResult.error(
          'Não é possível remover o dia ${day.label} (${AppFormatters.date(day.date)}): '
          'existem $deps. Reatribua ou remova esses vínculos antes de alterar as datas.',
        );
      }
    }

    final next = <EventDay>[];
    for (final date in desiredDates) {
      final kept = existingByDate[date];
      if (kept != null) {
        next.add(
          EventDay(
            id: kept.id,
            eventId: eventId,
            date: date,
            label: AppFormatters.weekday(date),
          ),
        );
      } else {
        next.add(
          EventDay(
            id: _uuid.v4(),
            eventId: eventId,
            date: date,
            label: AppFormatters.weekday(date),
          ),
        );
      }
    }

    _days
      ..removeWhere((d) => d.eventId == eventId)
      ..addAll(next);
    return const StoreResult.ok();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Retorna descrição das dependências ou null se o dia puder ser removido.
  String? _describeDayDependencies(String eventId, String dayId) {
    final passengerCount =
        _passengers.where((p) => p.eventId == eventId && p.dayIds.contains(dayId)).length;
    final allocationCount = _allocations.where((a) {
      if (a.dayId != dayId) return false;
      final p = passengerById(a.passengerId);
      return p != null && p.eventId == eventId;
    }).length;

    // Pagamentos ficam na passagem (paidCents), não por dia; a dependência
    // financeira relevante para o dia é via passageiros daquele dia.
    if (passengerCount == 0 && allocationCount == 0) return null;

    final parts = <String>[];
    if (passengerCount > 0) {
      parts.add(
        passengerCount == 1 ? '1 passageiro vinculado' : '$passengerCount passageiros vinculados',
      );
    }
    if (allocationCount > 0) {
      parts.add(
        allocationCount == 1 ? '1 alocação' : '$allocationCount alocações',
      );
    }
    return parts.join(' e ');
  }

  StoreResult addVehicle({
    required String eventId,
    required String name,
    required VehicleType type,
    required int physicalCapacity,
    required int localCapacity,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    if (name.trim().isEmpty) return const StoreResult.error('Informe o nome do veículo.');
    if (localCapacity <= 0 || physicalCapacity <= 0) {
      return const StoreResult.error('Capacidade inválida.');
    }
    if (localCapacity > physicalCapacity) {
      return const StoreResult.error('O limite local não pode ultrapassar a capacidade física.');
    }
    _vehicles.add(
      Vehicle(
        id: _uuid.v4(),
        eventId: eventId,
        name: name.trim(),
        type: type,
        physicalCapacity: physicalCapacity,
        localCapacity: localCapacity,
      ),
    );
    _log(eventId, 'Veículo "${name.trim()}" criado ($localCapacity vagas locais).');
    _changed();
    return const StoreResult.ok();
  }

  StoreResult updateVehicle(Vehicle vehicle) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final i = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (i < 0) return const StoreResult.error('Veículo não encontrado.');
    if (vehicle.localCapacity > vehicle.physicalCapacity) {
      return const StoreResult.error('O limite local não pode ultrapassar a capacidade física.');
    }
    _vehicles[i] = vehicle;
    _log(vehicle.eventId, 'Veículo "${vehicle.name}" atualizado.');
    _changed();
    return const StoreResult.ok();
  }

  StoreResult? _validatePassageInput({
    required TransportEvent event,
    required String buyerName,
    required List<PassengerDraft> passengers,
    bool confirmBypass = false,
    bool enforceDeadline = true,
  }) {
    if (buyerName.trim().isEmpty) return const StoreResult.error('Informe o comprador.');
    if (passengers.isEmpty) return const StoreResult.error('Inclua ao menos um passageiro.');
    if (enforceDeadline && event.passageDeadlinePassed && !confirmBypass) {
      return const StoreResult.confirm(
        'O prazo de passagens já passou. Registrar mesmo assim? A exceção será gravada no histórico.',
      );
    }
    for (final d in passengers) {
      final err = validateExemption(
        category: d.category,
        birthDate: d.birthDate,
        event: event,
      );
      if (err != null) return StoreResult.error('${d.name}: $err');
      if (d.name.trim().isEmpty) return const StoreResult.error('Nome do passageiro obrigatório.');
      if (d.dayIds.isEmpty) return StoreResult.error('${d.name}: selecione os dias de viagem.');
      if ((d.category == PassengerCategory.minor || d.category == PassengerCategory.student) &&
          (d.responsibleName == null || d.responsibleName!.trim().isEmpty)) {
        return StoreResult.error('${d.name}: informe o responsável.');
      }
    }
    return null;
  }

  StoreResult createPassage({
    required String eventId,
    required String buyerName,
    required int paidCents,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
    List<String> receiptNotes = const [],
    bool confirmBypass = false,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final event = eventById(eventId);
    if (event == null) return const StoreResult.error('Evento não encontrado.');
    final validation = _validatePassageInput(
      event: event,
      buyerName: buyerName,
      passengers: passengers,
      confirmBypass: confirmBypass,
    );
    if (validation != null) return validation;

    final passageId = _uuid.v4();
    final ids = <String>[];
    for (final d in passengers) {
      final pid = _uuid.v4();
      ids.add(pid);
      final passenger = Passenger(
        id: pid,
        eventId: eventId,
        passageId: passageId,
        name: d.name.trim(),
        documentType: d.documentType,
        documentNumber: d.documentNumber,
        birthDate: d.birthDate,
        category: d.category,
        responsibleName: d.responsibleName,
        dayIds: List<String>.from(d.dayIds),
      );
      _passengers.add(passenger);
      _rememberPerson(passenger);
    }
    _passages.add(
      PassageGroup(
        id: passageId,
        eventId: eventId,
        buyerName: buyerName.trim(),
        passengerIds: ids,
        paidCents: paidCents,
        paymentMethod: method,
        receiptNotes: receiptNotes,
        createdAt: DateTime.now(),
        deadlineBypass: event.passageDeadlinePassed,
        paymentRecords: paidCents > 0
            ? [PaymentRecord(amountCents: paidCents, method: method)]
            : const [],
      ),
    );
    _log(
      eventId,
      'Passagem de ${buyerName.trim()} (${ids.length} passageiro(s))'
      '${event.passageDeadlinePassed ? ' — após o prazo (exceção)' : ''}.',
    );
    _changed();
    return const StoreResult.ok();
  }

  /// Atualiza metadados editáveis e passageiros vinculados.
  /// Preserva `id`, `createdAt`, `paidCents` e `receiptNotes` (histórico financeiro).
  StoreResult updatePassage({
    required String passageId,
    required String eventId,
    required String buyerName,
    required PaymentMethod method,
    required List<PassengerDraft> passengers,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final index = _passages.indexWhere((p) => p.id == passageId);
    if (index < 0) return const StoreResult.error('Passagem não encontrada.');
    final current = _passages[index];
    if (current.eventId != eventId) {
      return const StoreResult.error('A passagem não pertence a este evento.');
    }
    final event = eventById(eventId);
    if (event == null) return const StoreResult.error('Evento não encontrado.');

    final validation = _validatePassageInput(
      event: event,
      buyerName: buyerName,
      passengers: passengers,
      enforceDeadline: false,
    );
    if (validation != null) return validation;

    final existingIds = current.passengerIds.toSet();
    final keptIds = <String>{};
    for (final d in passengers) {
      final id = d.id;
      if (id == null) continue;
      if (!existingIds.contains(id)) {
        return StoreResult.error('Passageiro inválido na passagem: ${d.name}.');
      }
      final p = passengerById(id);
      if (p == null || p.passageId != passageId || p.eventId != eventId) {
        return StoreResult.error('Passageiro inválido na passagem: ${d.name}.');
      }
      keptIds.add(id);
    }

    final removedIds = existingIds.difference(keptIds);
    for (final removedId in removedIds) {
      final activeAlloc = _allocations.any(
        (a) => a.passengerId == removedId && a.isActive,
      );
      if (activeAlloc) {
        final name = passengerById(removedId)?.name ?? removedId;
        return StoreResult.error(
          'Não é possível remover $name: ainda há alocação ativa. '
          'Desfaça a alocação antes.',
        );
      }
    }

    final nextPassengerIds = <String>[];
    for (final d in passengers) {
      if (d.id != null) {
        final pi = _passengers.indexWhere((p) => p.id == d.id);
        if (pi < 0) return StoreResult.error('Passageiro não encontrado: ${d.name}.');
        final updated = _passengers[pi].copyWith(
          name: d.name.trim(),
          documentType: d.documentType,
          documentNumber: d.documentNumber,
          birthDate: d.birthDate,
          category: d.category,
          responsibleName: d.responsibleName,
          dayIds: List<String>.from(d.dayIds),
        );
        _passengers[pi] = updated;
        _rememberPerson(updated);
        nextPassengerIds.add(d.id!);
      } else {
        final pid = _uuid.v4();
        final passenger = Passenger(
          id: pid,
          eventId: eventId,
          passageId: passageId,
          name: d.name.trim(),
          documentType: d.documentType,
          documentNumber: d.documentNumber,
          birthDate: d.birthDate,
          category: d.category,
          responsibleName: d.responsibleName,
          dayIds: List<String>.from(d.dayIds),
        );
        _passengers.add(passenger);
        _rememberPerson(passenger);
        nextPassengerIds.add(pid);
      }
    }

    for (final removedId in removedIds) {
      _passengers.removeWhere((p) => p.id == removedId);
      _allocations.removeWhere((a) => a.passengerId == removedId);
      _checkIns.removeWhere((c) {
        // check-ins órfãos de alocações já removidas — limpeza por alocação ausente
        return !_allocations.any((a) => a.id == c.allocationId);
      });
    }

    // paidCents e receiptNotes permanece — histórico financeiro intacto.
    _passages[index] = current.copyWith(
      buyerName: buyerName.trim(),
      paymentMethod: method,
      passengerIds: nextPassengerIds,
    );
    _log(
      eventId,
      'Passagem de ${buyerName.trim()} atualizada (${nextPassengerIds.length} passageiro(s)).',
    );
    _changed();
    return const StoreResult.ok();
  }

  StoreResult addPayment({
    required String passageId,
    required int extraCents,
    required PaymentMethod method,
    String? receiptNote,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final i = _passages.indexWhere((p) => p.id == passageId);
    if (i < 0) return const StoreResult.error('Passagem não encontrada.');
    if (extraCents <= 0) return const StoreResult.error('Valor inválido.');
    final current = _passages[i];
    final notes = [...current.receiptNotes];
    if (receiptNote != null && receiptNote.trim().isNotEmpty) {
      notes.add(receiptNote.trim());
    }
    final records = [
      ...current.paymentRecords,
      PaymentRecord(amountCents: extraCents, method: method),
    ];
    _passages[i] = current.copyWith(
      paidCents: current.paidCents + extraCents,
      receiptNotes: notes,
      paymentRecords: records,
    );
    _log(current.eventId, 'Pagamento extra em ${current.buyerName} (${method.label}).');
    _changed();
    return const StoreResult.ok();
  }

  StoreResult updatePassengerDays({
    required String passengerId,
    required List<String> dayIds,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final i = _passengers.indexWhere((p) => p.id == passengerId);
    if (i < 0) return const StoreResult.error('Passageiro não encontrado.');
    if (dayIds.isEmpty) return const StoreResult.error('Selecione ao menos um dia.');
    _passengers[i] = _passengers[i].copyWith(dayIds: dayIds);
    _log(_passengers[i].eventId, 'Dias de ${_passengers[i].name} atualizados.');
    _changed();
    return const StoreResult.ok();
  }

  StoreResult allocate({
    required String passengerId,
    required String vehicleId,
    required String dayId,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final passenger = passengerById(passengerId);
    final vehicle = vehicleById(vehicleId);
    if (passenger == null || vehicle == null) {
      return const StoreResult.error('Passageiro ou veículo inválido.');
    }
    if (!passenger.dayIds.contains(dayId)) {
      return const StoreResult.error('Este passageiro não viaja neste dia.');
    }
    if (_allocations.any((a) => a.passengerId == passengerId && a.dayId == dayId && a.isActive)) {
      return const StoreResult.error('Passageiro já alocado neste dia.');
    }
    final occupied = _allocations
        .where((a) => a.vehicleId == vehicleId && a.dayId == dayId && a.isActive)
        .length;
    if (occupied >= vehicle.localCapacity) {
      return StoreResult.error('Veículo lotado neste dia (${vehicle.localCapacity} vagas locais).');
    }
    final next = occupied + 1;
    _allocations.add(
      Allocation(
        id: _uuid.v4(),
        passengerId: passengerId,
        vehicleId: vehicleId,
        dayId: dayId,
        position: next,
      ),
    );
    _log(passenger.eventId, '${passenger.name} alocado em ${vehicle.name}.');
    _changed();
    return const StoreResult.ok();
  }

  StoreResult relocate({
    required String allocationId,
    required String targetVehicleId,
    bool confirmed = false,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final i = _allocations.indexWhere((a) => a.id == allocationId);
    if (i < 0) return const StoreResult.error('Alocação não encontrada.');
    final current = _allocations[i];
    if (current.vehicleId == targetVehicleId) {
      return const StoreResult.error('O passageiro já está neste veículo.');
    }
    final dest = vehicleById(targetVehicleId);
    final origin = vehicleById(current.vehicleId);
    final passenger = passengerById(current.passengerId);
    if (dest == null || origin == null || passenger == null) {
      return const StoreResult.error('Dados incompletos.');
    }
    if (!confirmed) {
      return StoreResult.confirm(
        'Transferir ${passenger.name} de ${origin.name} para ${dest.name}?',
      );
    }
    final occupied = _allocations
        .where((a) => a.vehicleId == targetVehicleId && a.dayId == current.dayId && a.isActive)
        .length;
    if (occupied >= dest.localCapacity) {
      return const StoreResult.error('Veículo de destino lotado.');
    }
    _allocations[i] = current.copyWith(
      status: AllocationStatus.relocated,
      relocatedToVehicleId: targetVehicleId,
    );
    _allocations.add(
      Allocation(
        id: _uuid.v4(),
        passengerId: current.passengerId,
        vehicleId: targetVehicleId,
        dayId: current.dayId,
        position: occupied + 1,
      ),
    );
    _log(
      passenger.eventId,
      '${passenger.name} realocado de ${origin.name} para ${dest.name}.',
    );
    _changed();
    return const StoreResult.ok();
  }

  StoreResult markDesisted({
    required String allocationId,
    PassengerDraft? substitute,
    bool confirmRelocate = false,
  }) {
    if (!_canEdit()) return const StoreResult.error('Sem permissão.');
    final i = _allocations.indexWhere((a) => a.id == allocationId);
    if (i < 0) return const StoreResult.error('Alocação não encontrada.');
    final current = _allocations[i];
    final passenger = passengerById(current.passengerId);
    if (passenger == null) return const StoreResult.error('Passageiro não encontrado.');
    final event = eventById(passenger.eventId)!;
    final vehicle = vehicleById(current.vehicleId)!;

    if (substitute == null) {
      _allocations[i] = current.copyWith(status: AllocationStatus.desisted);
      _log(event.id, '${passenger.name} marcado como desistente em ${vehicle.name}. Vaga liberada.');
      _changed();
      return const StoreResult.ok();
    }

    Passenger? existing;
    for (final p in _passengers) {
      if (p.eventId == event.id && p.name.toLowerCase() == substitute.name.trim().toLowerCase()) {
        existing = p;
        break;
      }
    }

    if (existing != null) {
      Allocation? other;
      for (final a in _allocations) {
        if (a.passengerId == existing.id && a.dayId == current.dayId && a.isActive) {
          other = a;
          break;
        }
      }
      if (other != null && other.vehicleId != current.vehicleId && !confirmRelocate) {
        final from = vehicleById(other.vehicleId)?.name ?? 'outro ônibus';
        return StoreResult.confirm(
          '${substitute.name} já está em $from. Transferir para ${vehicle.name}?',
        );
      }
      if (other != null && other.vehicleId != current.vehicleId) {
        relocate(allocationId: other.id, targetVehicleId: current.vehicleId, confirmed: true);
      }
      _allocations[i] = current.copyWith(
        status: AllocationStatus.desisted,
        substitutePassengerId: existing.id,
      );
      if (other == null) {
        allocate(passengerId: existing.id, vehicleId: current.vehicleId, dayId: current.dayId);
      }
      _log(event.id, '${passenger.name} desistiu → ${existing.name} assume a vaga.');
      _changed();
      return const StoreResult.ok();
    }

    final err = validateExemption(
      category: substitute.category,
      birthDate: substitute.birthDate,
      event: event,
    );
    if (err != null) return StoreResult.error(err);

    final newId = _uuid.v4();
    _passengers.add(
      Passenger(
        id: newId,
        eventId: event.id,
        passageId: passenger.passageId,
        name: substitute.name.trim(),
        documentType: substitute.documentType,
        documentNumber: substitute.documentNumber,
        birthDate: substitute.birthDate,
        category: substitute.category,
        responsibleName: substitute.responsibleName,
        dayIds: [current.dayId],
      ),
    );
    final passage = passageById(passenger.passageId);
    if (passage != null) {
      final pi = _passages.indexWhere((p) => p.id == passage.id);
      _passages[pi] = passage.copyWith(passengerIds: [...passage.passengerIds, newId]);
    }
    _allocations[i] = current.copyWith(
      status: AllocationStatus.desisted,
      substitutePassengerId: newId,
    );
    _allocations.add(
      Allocation(
        id: _uuid.v4(),
        passengerId: newId,
        vehicleId: current.vehicleId,
        dayId: current.dayId,
        position: current.position,
        replacedPassengerId: passenger.id,
      ),
    );
    _rememberPerson(_passengers.last);
    _log(event.id, '${passenger.name} desistiu → substituto ${substitute.name.trim()}.');
    _changed();
    return const StoreResult.ok();
  }

  bool hasCheckIn(String allocationId, String direction) =>
      _checkIns.any((c) => c.allocationId == allocationId && c.direction == direction);

  StoreResult performCheckIn(String allocationId, String direction) {
    final eventUser = user;
    final allocation = _allocations.cast<Allocation?>().firstWhere(
          (a) => a?.id == allocationId,
          orElse: () => null,
        );
    if (allocation == null || !allocation.isActive) {
      return const StoreResult.error('Check-in indisponível para esta linha.');
    }
    final passenger = passengerById(allocation.passengerId);
    if (passenger == null) return const StoreResult.error('Passageiro não encontrado.');
    final event = eventById(passenger.eventId);
    if (event == null || eventUser == null || !eventUser.canCheckIn(event)) {
      return const StoreResult.error('Você não tem permissão de check-in neste evento.');
    }
    if (hasCheckIn(allocationId, direction)) {
      return const StoreResult.error('Check-in já registrado.');
    }
    _checkIns.add(
      CheckInRecord(allocationId: allocationId, direction: direction, at: DateTime.now()),
    );
    _log(event.id, 'Check-in ${direction == 'OUTBOUND' ? 'ida' : 'volta'}: ${passenger.name}.');
    _changed();
    return const StoreResult.ok();
  }

  bool _canEdit() {
    final u = _user;
    return u != null && u.canEditOperations;
  }

  void _rememberPerson(Passenger p) {
    _people.removeWhere((x) => x.fullName.toLowerCase() == p.name.toLowerCase());
    _people.add(
      PersonMemory(
        fullName: p.name,
        documentType: p.documentType,
        documentNumber: p.documentNumber,
        birthDate: p.birthDate,
        responsibleName: p.responsibleName,
      ),
    );
  }

  void _log(String eventId, String message) {
    _activity.insert(
      0,
      ActivityEntry(
        id: _uuid.v4(),
        eventId: eventId,
        message: message,
        at: DateTime.now(),
        actorName: _user?.name ?? 'Sistema',
      ),
    );
  }

  Map<String, dynamic> _toMap() => {
        'user': _user?.toJson(),
        'events': _events.map((e) => e.toJson()).toList(),
        'days': _days.map((e) => e.toJson()).toList(),
        'vehicles': _vehicles.map((e) => e.toJson()).toList(),
        'passengers': _passengers.map((e) => e.toJson()).toList(),
        'allocations': _allocations.map((e) => e.toJson()).toList(),
        'passages': _passages.map((e) => e.toJson()).toList(),
        'checkIns': _checkIns.map((e) => e.toJson()).toList(),
        'people': _people.map((e) => e.toJson()).toList(),
        'activity': _activity.map((e) => e.toJson()).toList(),
      };

  List<String> _fromMap(Map<String, dynamic> map) {
    final errors = <String>[];

    AppUser? parsedUser;
    final userRaw = map['user'];
    if (userRaw != null) {
      if (userRaw is Map<String, dynamic>) {
        try {
          parsedUser = AppUser.fromJson(userRaw);
        } catch (e) {
          errors.add('Falha ao ler usuário: $e');
        }
      } else {
        errors.add('Campo "user" com formato inválido');
      }
    }

    final parsedEvents = <TransportEvent>[];
    final eventsRaw = map['events'];
    if (eventsRaw is List) {
      for (var i = 0; i < eventsRaw.length; i++) {
        final item = eventsRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedEvents.add(TransportEvent.fromJson(item));
          } catch (e) {
            errors.add('Evento no índice $i inválido: $e');
          }
        } else {
          errors.add('Evento no índice $i não é um objeto válido');
        }
      }
    } else if (eventsRaw != null) {
      errors.add('Campo "events" deve ser uma lista');
    }

    final parsedDays = <EventDay>[];
    final daysRaw = map['days'];
    if (daysRaw is List) {
      for (var i = 0; i < daysRaw.length; i++) {
        final item = daysRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedDays.add(EventDay.fromJson(item));
          } catch (e) {
            errors.add('Dia no índice $i inválido: $e');
          }
        } else {
          errors.add('Dia no índice $i não é um objeto válido');
        }
      }
    } else if (daysRaw != null) {
      errors.add('Campo "days" deve ser uma lista');
    }

    final parsedVehicles = <Vehicle>[];
    final vehiclesRaw = map['vehicles'];
    if (vehiclesRaw is List) {
      for (var i = 0; i < vehiclesRaw.length; i++) {
        final item = vehiclesRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedVehicles.add(Vehicle.fromJson(item));
          } catch (e) {
            errors.add('Veículo no índice $i inválido: $e');
          }
        } else {
          errors.add('Veículo no índice $i não é um objeto válido');
        }
      }
    } else if (vehiclesRaw != null) {
      errors.add('Campo "vehicles" deve ser uma lista');
    }

    final parsedPassengers = <Passenger>[];
    final passengersRaw = map['passengers'];
    if (passengersRaw is List) {
      for (var i = 0; i < passengersRaw.length; i++) {
        final item = passengersRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedPassengers.add(Passenger.fromJson(item));
          } catch (e) {
            errors.add('Passageiro no índice $i inválido: $e');
          }
        } else {
          errors.add('Passageiro no índice $i não é um objeto válido');
        }
      }
    } else if (passengersRaw != null) {
      errors.add('Campo "passengers" deve ser uma lista');
    }

    final parsedAllocations = <Allocation>[];
    final allocationsRaw = map['allocations'];
    if (allocationsRaw is List) {
      for (var i = 0; i < allocationsRaw.length; i++) {
        final item = allocationsRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedAllocations.add(Allocation.fromJson(item));
          } catch (e) {
            errors.add('Alocação no índice $i inválida: $e');
          }
        } else {
          errors.add('Alocação no índice $i não é um objeto válido');
        }
      }
    } else if (allocationsRaw != null) {
      errors.add('Campo "allocations" deve ser uma lista');
    }

    final parsedPassages = <PassageGroup>[];
    final passagesRaw = map['passages'];
    if (passagesRaw is List) {
      for (var i = 0; i < passagesRaw.length; i++) {
        final item = passagesRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedPassages.add(PassageGroup.fromJson(item));
          } catch (e) {
            errors.add('Passagem no índice $i inválida: $e');
          }
        } else {
          errors.add('Passagem no índice $i não é um objeto válido');
        }
      }
    } else if (passagesRaw != null) {
      errors.add('Campo "passages" deve ser uma lista');
    }

    final parsedCheckIns = <CheckInRecord>[];
    final checkInsRaw = map['checkIns'];
    if (checkInsRaw is List) {
      for (var i = 0; i < checkInsRaw.length; i++) {
        final item = checkInsRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedCheckIns.add(CheckInRecord.fromJson(item));
          } catch (e) {
            errors.add('Check-in no índice $i inválido: $e');
          }
        }
      }
    }

    final parsedPeople = <PersonMemory>[];
    final peopleRaw = map['people'];
    if (peopleRaw is List) {
      for (var i = 0; i < peopleRaw.length; i++) {
        final item = peopleRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedPeople.add(PersonMemory.fromJson(item));
          } catch (e) {
            errors.add('Pessoa no índice $i inválida: $e');
          }
        }
      }
    }

    final parsedActivity = <ActivityEntry>[];
    final activityRaw = map['activity'];
    if (activityRaw is List) {
      for (var i = 0; i < activityRaw.length; i++) {
        final item = activityRaw[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedActivity.add(ActivityEntry.fromJson(item));
          } catch (e) {
            errors.add('Histórico no índice $i inválido: $e');
          }
        }
      }
    }

    _user = parsedUser;
    _events = parsedEvents;
    _days = parsedDays;
    _vehicles = parsedVehicles;
    _passengers = parsedPassengers;
    _allocations = parsedAllocations;
    _passages = parsedPassages;
    _checkIns = parsedCheckIns;
    _people = parsedPeople;
    _activity = parsedActivity;

    return errors;
  }
}

class PassengerDraft {
  /// ID do passageiro existente (modo edição). Null = novo passageiro.
  final String? id;
  final String name;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;
  final PassengerCategory category;
  final String? responsibleName;
  final List<String> dayIds;

  const PassengerDraft({
    this.id,
    required this.name,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.category = PassengerCategory.adult,
    this.responsibleName,
    required this.dayIds,
  });
}
