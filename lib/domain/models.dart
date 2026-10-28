import 'package:flutter/foundation.dart';

enum UserRole { coordinator, coordinatorHelper, captain, captainHelper }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.coordinator => 'Coordenador',
        UserRole.coordinatorHelper => 'Ajudante do coordenador',
        UserRole.captain => 'Capitão de ônibus',
        UserRole.captainHelper => 'Ajudante do capitão',
      };
}

enum EventKind { circuitAssembly, regionalConvention, other }

extension EventKindLabel on EventKind {
  String get label => switch (this) {
        EventKind.circuitAssembly => 'Assembleia de circuito',
        EventKind.regionalConvention => 'Congresso regional',
        EventKind.other => 'Outro',
      };
}

enum EventLifecycle { draft, open, inProgress, completed }

extension EventLifecycleLabel on EventLifecycle {
  String get label => switch (this) {
        EventLifecycle.draft => 'Rascunho',
        EventLifecycle.open => 'Aberto',
        EventLifecycle.inProgress => 'Em andamento',
        EventLifecycle.completed => 'Concluído',
      };
}

enum VehicleType { bus, car }

extension VehicleTypeLabel on VehicleType {
  String get label => this == VehicleType.bus ? 'Ônibus' : 'Carro';
}

enum PassengerCategory { adult, student, minor, exempt }

extension PassengerCategoryLabel on PassengerCategory {
  String get label => switch (this) {
        PassengerCategory.adult => 'Adulto',
        PassengerCategory.student => 'Estudante',
        PassengerCategory.minor => 'Menor',
        PassengerCategory.exempt => 'Isento',
      };
}

enum AllocationStatus { active, desisted, relocated }

enum PaymentMethod { pix, cash }

extension PaymentMethodLabel on PaymentMethod {
  String get label => this == PaymentMethod.pix ? 'PIX' : 'Espécie';
}

enum FinancialStatus { unpaid, partial, paid, overpaid, notApplicable }

extension FinancialStatusLabel on FinancialStatus {
  String get label => switch (this) {
        FinancialStatus.unpaid => 'Pendente de pagamento',
        FinancialStatus.partial => 'Pagamento parcial',
        FinancialStatus.paid => 'Pago',
        FinancialStatus.overpaid => 'Pago a mais',
        FinancialStatus.notApplicable => 'Isento / N/A',
      };
}

@immutable
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? assignedVehicleId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedVehicleId,
  });

  bool get canViewFinance =>
      role == UserRole.coordinator || role == UserRole.coordinatorHelper;

  bool get canManageEvent => role == UserRole.coordinator;

  bool get canEditOperations =>
      role == UserRole.coordinator || role == UserRole.coordinatorHelper;

  bool canCheckIn(TransportEvent event) {
    if (role == UserRole.coordinator || role == UserRole.coordinatorHelper) {
      return true;
    }
    if (role == UserRole.captain) return event.captainCheckinEnabled;
    return event.helperCheckinEnabled;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'assignedVehicleId': assignedVehicleId,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? 'local-user',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.coordinator,
        ),
        assignedVehicleId: json['assignedVehicleId'] as String?,
      );
}

@immutable
class TransportEvent {
  final String id;
  final String theme;
  final EventKind kind;
  final EventLifecycle lifecycle;
  final DateTime startDate;
  final DateTime endDate;
  final int dailyFareCents;
  final int minimumPayingAge;
  final DateTime? passageDeadline;
  final DateTime? preliminaryListDeadline;
  final DateTime? finalListDeadline;
  final bool captainCheckinEnabled;
  final bool helperCheckinEnabled;

  const TransportEvent({
    required this.id,
    required this.theme,
    required this.kind,
    required this.lifecycle,
    required this.startDate,
    required this.endDate,
    required this.dailyFareCents,
    this.minimumPayingAge = 6,
    this.passageDeadline,
    this.preliminaryListDeadline,
    this.finalListDeadline,
    this.captainCheckinEnabled = true,
    this.helperCheckinEnabled = false,
  });

  int get dayCount => endDate.difference(startDate).inDays + 1;

  bool get passageDeadlinePassed =>
      passageDeadline != null && DateTime.now().isAfter(passageDeadline!);

  TransportEvent copyWith({
    String? theme,
    EventKind? kind,
    EventLifecycle? lifecycle,
    DateTime? startDate,
    DateTime? endDate,
    int? dailyFareCents,
    int? minimumPayingAge,
    DateTime? passageDeadline,
    DateTime? preliminaryListDeadline,
    DateTime? finalListDeadline,
    bool? captainCheckinEnabled,
    bool? helperCheckinEnabled,
    bool clearPassageDeadline = false,
    bool clearPreliminary = false,
    bool clearFinal = false,
  }) {
    return TransportEvent(
      id: id,
      theme: theme ?? this.theme,
      kind: kind ?? this.kind,
      lifecycle: lifecycle ?? this.lifecycle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyFareCents: dailyFareCents ?? this.dailyFareCents,
      minimumPayingAge: minimumPayingAge ?? this.minimumPayingAge,
      passageDeadline:
          clearPassageDeadline ? null : (passageDeadline ?? this.passageDeadline),
      preliminaryListDeadline: clearPreliminary
          ? null
          : (preliminaryListDeadline ?? this.preliminaryListDeadline),
      finalListDeadline:
          clearFinal ? null : (finalListDeadline ?? this.finalListDeadline),
      captainCheckinEnabled: captainCheckinEnabled ?? this.captainCheckinEnabled,
      helperCheckinEnabled: helperCheckinEnabled ?? this.helperCheckinEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'theme': theme,
        'kind': kind.name,
        'lifecycle': lifecycle.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dailyFareCents': dailyFareCents,
        'minimumPayingAge': minimumPayingAge,
        'passageDeadline': passageDeadline?.toIso8601String(),
        'preliminaryListDeadline': preliminaryListDeadline?.toIso8601String(),
        'finalListDeadline': finalListDeadline?.toIso8601String(),
        'captainCheckinEnabled': captainCheckinEnabled,
        'helperCheckinEnabled': helperCheckinEnabled,
      };

  factory TransportEvent.fromJson(Map<String, dynamic> json) => TransportEvent(
        id: json['id'] as String? ?? '',
        theme: json['theme'] as String? ?? 'Evento sem tema',
        kind: EventKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => EventKind.other,
        ),
        lifecycle: EventLifecycle.values.firstWhere(
          (l) => l.name == json['lifecycle'],
          orElse: () => EventLifecycle.open,
        ),
        startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
        dailyFareCents: (json['dailyFareCents'] as num?)?.toInt() ?? 0,
        minimumPayingAge: (json['minimumPayingAge'] as num?)?.toInt() ?? 6,
        passageDeadline: json['passageDeadline'] != null
            ? DateTime.tryParse(json['passageDeadline'] as String)
            : null,
        preliminaryListDeadline: json['preliminaryListDeadline'] != null
            ? DateTime.tryParse(json['preliminaryListDeadline'] as String)
            : null,
        finalListDeadline: json['finalListDeadline'] != null
            ? DateTime.tryParse(json['finalListDeadline'] as String)
            : null,
        captainCheckinEnabled: json['captainCheckinEnabled'] as bool? ?? true,
        helperCheckinEnabled: json['helperCheckinEnabled'] as bool? ?? false,
      );
}

@immutable
class EventDay {
  final String id;
  final String eventId;
  final DateTime date;
  final String label;

  const EventDay({
    required this.id,
    required this.eventId,
    required this.date,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'date': date.toIso8601String(),
        'label': label,
      };

  factory EventDay.fromJson(Map<String, dynamic> json) => EventDay(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        label: json['label'] as String? ?? '',
      );
}

@immutable
class Vehicle {
  final String id;
  final String eventId;
  final String name;
  final VehicleType type;
  final int physicalCapacity;
  final int localCapacity;

  const Vehicle({
    required this.id,
    required this.eventId,
    required this.name,
    this.type = VehicleType.bus,
    required this.physicalCapacity,
    required this.localCapacity,
  });

  int get capacity => localCapacity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'name': name,
        'type': type.name,
        'physicalCapacity': physicalCapacity,
        'localCapacity': localCapacity,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: VehicleType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => VehicleType.bus,
        ),
        physicalCapacity: (json['physicalCapacity'] as num?)?.toInt() ??
            (json['capacity'] as num?)?.toInt() ??
            0,
        localCapacity: (json['localCapacity'] as num?)?.toInt() ??
            (json['capacity'] as num?)?.toInt() ??
            0,
      );
}

@immutable
class PersonMemory {
  final String fullName;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;
  final String? responsibleName;

  const PersonMemory({
    required this.fullName,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.responsibleName,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'birthDate': birthDate?.toIso8601String(),
        'responsibleName': responsibleName,
      };

  factory PersonMemory.fromJson(Map<String, dynamic> json) => PersonMemory(
        fullName: json['fullName'] as String? ?? '',
        documentType: json['documentType'] as String?,
        documentNumber: json['documentNumber'] as String?,
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate'] as String)
            : null,
        responsibleName: json['responsibleName'] as String?,
      );
}

@immutable
class Passenger {
  final String id;
  final String eventId;
  final String passageId;
  final String name;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;
  final PassengerCategory category;
  final String? responsibleName;
  final List<String> dayIds;

  const Passenger({
    required this.id,
    required this.eventId,
    required this.passageId,
    required this.name,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.category = PassengerCategory.adult,
    this.responsibleName,
    required this.dayIds,
  });

  bool get isExempt => category == PassengerCategory.exempt;
  bool get needsResponsible =>
      category == PassengerCategory.minor || category == PassengerCategory.student;
  bool get missingDocument =>
      documentNumber == null || documentNumber!.trim().isEmpty;
  bool get missingResponsible =>
      needsResponsible && (responsibleName == null || responsibleName!.trim().isEmpty);
  bool get hasDataPending => missingDocument || missingResponsible;

  Passenger copyWith({
    String? name,
    String? documentType,
    String? documentNumber,
    DateTime? birthDate,
    PassengerCategory? category,
    String? responsibleName,
    List<String>? dayIds,
    String? passageId,
  }) {
    return Passenger(
      id: id,
      eventId: eventId,
      passageId: passageId ?? this.passageId,
      name: name ?? this.name,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      birthDate: birthDate ?? this.birthDate,
      category: category ?? this.category,
      responsibleName: responsibleName ?? this.responsibleName,
      dayIds: dayIds ?? this.dayIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'passageId': passageId,
        'name': name,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'birthDate': birthDate?.toIso8601String(),
        'category': category.name,
        'responsibleName': responsibleName,
        'dayIds': dayIds,
      };

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        passageId: json['passageId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        documentType: json['documentType'] as String?,
        documentNumber: json['documentNumber'] as String?,
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate'] as String)
            : null,
        category: PassengerCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => PassengerCategory.adult,
        ),
        responsibleName: json['responsibleName'] as String?,
        dayIds: (json['dayIds'] as List?)?.whereType<String>().toList() ?? const [],
      );
}

@immutable
class Allocation {
  final String id;
  final String passengerId;
  final String vehicleId;
  final String dayId;
  final int position;
  final AllocationStatus status;
  final String? relocatedToVehicleId;
  final String? substitutePassengerId;
  final String? replacedPassengerId;

  const Allocation({
    required this.id,
    required this.passengerId,
    required this.vehicleId,
    required this.dayId,
    required this.position,
    this.status = AllocationStatus.active,
    this.relocatedToVehicleId,
    this.substitutePassengerId,
    this.replacedPassengerId,
  });

  bool get isActive => status == AllocationStatus.active;

  Allocation copyWith({
    AllocationStatus? status,
    int? position,
    String? relocatedToVehicleId,
    String? substitutePassengerId,
    String? replacedPassengerId,
    String? vehicleId,
  }) {
    return Allocation(
      id: id,
      passengerId: passengerId,
      vehicleId: vehicleId ?? this.vehicleId,
      dayId: dayId,
      position: position ?? this.position,
      status: status ?? this.status,
      relocatedToVehicleId: relocatedToVehicleId ?? this.relocatedToVehicleId,
      substitutePassengerId: substitutePassengerId ?? this.substitutePassengerId,
      replacedPassengerId: replacedPassengerId ?? this.replacedPassengerId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'passengerId': passengerId,
        'vehicleId': vehicleId,
        'dayId': dayId,
        'position': position,
        'status': status.name,
        'relocatedToVehicleId': relocatedToVehicleId,
        'substitutePassengerId': substitutePassengerId,
        'replacedPassengerId': replacedPassengerId,
      };

  factory Allocation.fromJson(Map<String, dynamic> json) => Allocation(
        id: json['id'] as String? ?? '',
        passengerId: json['passengerId'] as String? ?? '',
        vehicleId: json['vehicleId'] as String? ?? '',
        dayId: json['dayId'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        status: AllocationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AllocationStatus.active,
        ),
        relocatedToVehicleId: json['relocatedToVehicleId'] as String?,
        substitutePassengerId: json['substitutePassengerId'] as String?,
        replacedPassengerId: json['replacedPassengerId'] as String?,
      );
}

@immutable
class CheckInRecord {
  final String allocationId;
  final String direction;
  final DateTime at;

  const CheckInRecord({
    required this.allocationId,
    required this.direction,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'allocationId': allocationId,
        'direction': direction,
        'at': at.toIso8601String(),
      };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
        allocationId: json['allocationId'] as String? ?? '',
        direction: json['direction'] as String? ?? 'OUTBOUND',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

@immutable
class PassageGroup {
  final String id;
  final String eventId;
  final String buyerName;
  final List<String> passengerIds;
  final int paidCents;
  final PaymentMethod paymentMethod;
  final List<String> receiptNotes;
  final DateTime createdAt;
  final bool deadlineBypass;

  const PassageGroup({
    required this.id,
    required this.eventId,
    required this.buyerName,
    required this.passengerIds,
    required this.paidCents,
    this.paymentMethod = PaymentMethod.pix,
    this.receiptNotes = const [],
    required this.createdAt,
    this.deadlineBypass = false,
  });

  PassageGroup copyWith({
    String? buyerName,
    List<String>? passengerIds,
    int? paidCents,
    PaymentMethod? paymentMethod,
    List<String>? receiptNotes,
    bool? deadlineBypass,
  }) {
    return PassageGroup(
      id: id,
      eventId: eventId,
      buyerName: buyerName ?? this.buyerName,
      passengerIds: passengerIds ?? this.passengerIds,
      paidCents: paidCents ?? this.paidCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNotes: receiptNotes ?? this.receiptNotes,
      createdAt: createdAt,
      deadlineBypass: deadlineBypass ?? this.deadlineBypass,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'buyerName': buyerName,
        'passengerIds': passengerIds,
        'paidCents': paidCents,
        'paymentMethod': paymentMethod.name,
        'receiptNotes': receiptNotes,
        'createdAt': createdAt.toIso8601String(),
        'deadlineBypass': deadlineBypass,
      };

  factory PassageGroup.fromJson(Map<String, dynamic> json) => PassageGroup(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        buyerName: json['buyerName'] as String? ?? '',
        passengerIds: (json['passengerIds'] as List?)?.whereType<String>().toList() ?? const [],
        paidCents: (json['paidCents'] as num?)?.toInt() ?? 0,
        paymentMethod: PaymentMethod.values.firstWhere(
          (m) => m.name == json['paymentMethod'],
          orElse: () => PaymentMethod.pix,
        ),
        receiptNotes: (json['receiptNotes'] as List?)?.whereType<String>().toList() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        deadlineBypass: json['deadlineBypass'] as bool? ?? false,
      );
}

@immutable
class VehicleDayStats {
  final String vehicleId;
  final String vehicleName;
  final String dayId;
  final String dayLabel;
  final int occupied;
  final int capacity;

  const VehicleDayStats({
    required this.vehicleId,
    required this.vehicleName,
    required this.dayId,
    required this.dayLabel,
    required this.occupied,
    required this.capacity,
  });

  double get ratio => capacity == 0 ? 0 : occupied / capacity;
}

@immutable
class DayCount {
  final String dayId;
  final String label;
  final int passengers;

  const DayCount({required this.dayId, required this.label, required this.passengers});
}

@immutable
class FinanceSummary {
  final int expectedCents;
  final int paidCents;

  const FinanceSummary({required this.expectedCents, required this.paidCents});

  int get pendingCents => (expectedCents - paidCents).clamp(0, expectedCents);
}

@immutable
class ActivityEntry {
  final String id;
  final String eventId;
  final String message;
  final DateTime at;
  final String actorName;

  const ActivityEntry({
    required this.id,
    required this.eventId,
    required this.message,
    required this.at,
    required this.actorName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'message': message,
        'at': at.toIso8601String(),
        'actorName': actorName,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        message: json['message'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        actorName: json['actorName'] as String? ?? 'Sistema',
      );
}

class StoreResult {
  final bool ok;
  final String message;
  final bool needsConfirm;

  const StoreResult.ok([this.message = 'OK'])
      : ok = true,
        needsConfirm = false;

  const StoreResult.error(this.message)
      : ok = false,
        needsConfirm = false;

  const StoreResult.confirm(this.message)
      : ok = false,
        needsConfirm = true;
}
