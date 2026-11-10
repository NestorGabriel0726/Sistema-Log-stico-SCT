import '../../domain/models.dart';

String pgEventType(EventKind kind) => switch (kind) {
      EventKind.circuitAssembly => 'CIRCUIT_ASSEMBLY',
      EventKind.regionalConvention => 'REGIONAL_CONVENTION',
      EventKind.other => 'OTHER',
    };

EventKind eventKindFromPg(Object? value) {
  switch ('$value'.toUpperCase()) {
    case 'CIRCUIT_ASSEMBLY':
      return EventKind.circuitAssembly;
    case 'REGIONAL_CONVENTION':
      return EventKind.regionalConvention;
    default:
      return EventKind.other;
  }
}

String pgEventStatus(TransportEvent event) {
  if (event.isDeleted) return 'ARCHIVED';
  return switch (event.lifecycle) {
    EventLifecycle.draft => 'DRAFT',
    EventLifecycle.open => 'OPEN',
    EventLifecycle.inProgress => 'IN_PROGRESS',
    EventLifecycle.completed => 'COMPLETED',
  };
}

(EventLifecycle, DateTime?) lifecycleFromPg(Object? status, Object? updatedAt) {
  switch ('$status'.toUpperCase()) {
    case 'DRAFT':
      return (EventLifecycle.draft, null);
    case 'IN_PROGRESS':
      return (EventLifecycle.inProgress, null);
    case 'COMPLETED':
    case 'FINALIZED':
      return (EventLifecycle.completed, null);
    case 'ARCHIVED':
      return (
        EventLifecycle.completed,
        DateTime.tryParse('$updatedAt') ?? DateTime.now(),
      );
    default:
      return (EventLifecycle.open, null);
  }
}

String pgVehicleType(VehicleType type) =>
    type == VehicleType.car ? 'CAR' : 'BUS';

VehicleType vehicleTypeFromPg(Object? value) =>
    '$value'.toUpperCase() == 'CAR' ? VehicleType.car : VehicleType.bus;

String pgPassengerCategory(PassengerCategory c) => switch (c) {
      PassengerCategory.adult => 'ADULT',
      PassengerCategory.student => 'STUDENT',
      PassengerCategory.minor => 'MINOR',
      PassengerCategory.exempt => 'EXEMPT',
    };

PassengerCategory passengerCategoryFromPg(Object? value) {
  switch ('$value'.toUpperCase()) {
    case 'STUDENT':
      return PassengerCategory.student;
    case 'MINOR':
      return PassengerCategory.minor;
    case 'EXEMPT':
      return PassengerCategory.exempt;
    default:
      return PassengerCategory.adult;
  }
}

String pgPaymentMethod(PaymentMethod method) =>
    method == PaymentMethod.cash ? 'CASH' : 'PIX';

PaymentMethod paymentMethodFromPg(Object? value) =>
    '$value'.toUpperCase() == 'CASH' ? PaymentMethod.cash : PaymentMethod.pix;

String pgAllocationStatus(AllocationStatus status) => switch (status) {
      AllocationStatus.active => 'ACTIVE',
      AllocationStatus.relocated => 'RELOCATED',
      AllocationStatus.desisted => 'DESISTED',
    };

AllocationStatus allocationStatusFromPg(Object? value) {
  switch ('$value'.toUpperCase()) {
    case 'RELOCATED':
      return AllocationStatus.relocated;
    case 'DESISTED':
    case 'CANCELLED':
      return AllocationStatus.desisted;
    default:
      return AllocationStatus.active;
  }
}

UserRole userRoleFromStaff(Object? value) {
  switch ('$value'.toUpperCase()) {
    case 'COORDINATOR':
      return UserRole.coordinator;
    case 'COORDINATOR_HELPER':
      return UserRole.coordinatorHelper;
    case 'BUS_CAPTAIN':
      return UserRole.captain;
    default:
      return UserRole.captainHelper;
  }
}

UserRole strongestRole(Iterable<UserRole> roles) {
  const rank = {
    UserRole.coordinator: 4,
    UserRole.coordinatorHelper: 3,
    UserRole.captain: 2,
    UserRole.captainHelper: 1,
  };
  var best = UserRole.captainHelper;
  var bestRank = 0;
  for (final role in roles) {
    final r = rank[role] ?? 0;
    if (r > bestRank) {
      best = role;
      bestRank = r;
    }
  }
  return best;
}

DateTime? parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}

TransportEvent eventFromRow(Map<String, dynamic> row) {
  final life = lifecycleFromPg(row['status'], row['updated_at']);
  return TransportEvent(
    id: '${row['id']}',
    theme: '${row['theme'] ?? ''}',
    kind: eventKindFromPg(row['type']),
    lifecycle: life.$1,
    startDate: parseDate(row['start_date']) ?? DateTime.now(),
    endDate: parseDate(row['end_date']) ?? DateTime.now(),
    dailyFareCents: (row['daily_fare_cents'] as num?)?.toInt() ?? 0,
    minimumPayingAge: (row['minimum_paying_age'] as num?)?.toInt() ?? 6,
    passageDeadline: parseDate(row['passage_deadline']),
    preliminaryListDeadline: parseDate(row['preliminary_list_deadline']),
    finalListDeadline: parseDate(row['final_list_deadline']),
    captainCheckinEnabled: row['captain_checkin_enabled'] as bool? ?? true,
    helperCheckinEnabled: row['helper_checkin_enabled'] as bool? ?? false,
    deletedAt: life.$2,
  );
}

EventDay eventDayFromRow(Map<String, dynamic> row) {
  return EventDay(
    id: '${row['id']}',
    eventId: '${row['event_id']}',
    date: parseDate(row['event_date']) ?? DateTime.now(),
    label: '${row['label'] ?? ''}',
  );
}

VehicleStop vehicleStopFromRow(Map<String, dynamic> row) {
  return VehicleStop(
    id: '${row['id']}',
    name: '${row['name'] ?? ''}',
    reference: row['reference'] as String?,
    sequence: (row['sequence'] as num?)?.toInt() ?? 1,
  );
}

Vehicle vehicleFromRow(Map<String, dynamic> row) {
  final rawStops = row['vehicle_stops'];
  final stops = <VehicleStop>[];
  if (rawStops is List) {
    for (final item in rawStops) {
      if (item is Map<String, dynamic>) {
        stops.add(vehicleStopFromRow(item));
      }
    }
    stops.sort((a, b) => a.sequence.compareTo(b.sequence));
  }
  return Vehicle(
    id: '${row['id']}',
    eventId: '${row['event_id']}',
    name: '${row['name'] ?? ''}',
    type: vehicleTypeFromPg(row['type']),
    physicalCapacity: (row['physical_capacity'] as num?)?.toInt() ?? 0,
    localCapacity: (row['local_capacity'] as num?)?.toInt() ?? 0,
    stops: stops,
  );
}

Passenger passengerFromRow(Map<String, dynamic> row) {
  final days = <String>[];
  final rawDays = row['passenger_days'];
  if (rawDays is List) {
    for (final item in rawDays) {
      if (item is Map && item['event_day_id'] != null) {
        days.add('${item['event_day_id']}');
      }
    }
  }
  var passageId = '';
  final links = row['passage_passengers'];
  if (links is List && links.isNotEmpty && links.first is Map) {
    passageId = '${(links.first as Map)['passage_id'] ?? ''}';
  }
  return Passenger(
    id: '${row['id']}',
    eventId: '${row['event_id']}',
    passageId: passageId,
    name: '${row['full_name_snapshot'] ?? ''}',
    documentType: row['document_type_snapshot'] as String?,
    documentNumber: row['document_number_snapshot'] as String?,
    birthDate: parseDate(row['birth_date_snapshot']),
    category: passengerCategoryFromPg(row['category']),
    responsibleName: row['responsible_name_snapshot'] as String?,
    dayIds: days,
  );
}

PassageGroup passageFromRow(Map<String, dynamic> row) {
  final passengerIds = <String>[];
  final links = row['passage_passengers'];
  if (links is List) {
    for (final item in links) {
      if (item is Map && item['event_passenger_id'] != null) {
        passengerIds.add('${item['event_passenger_id']}');
      }
    }
  }
  final records = <PaymentRecord>[];
  final payments = row['payments'];
  if (payments is List) {
    for (final item in payments) {
      if (item is Map<String, dynamic>) {
        records.add(
          PaymentRecord(
            amountCents: (item['amount_cents'] as num?)?.toInt() ?? 0,
            method: paymentMethodFromPg(item['payment_method']),
          ),
        );
      }
    }
  }
  final paid = records.fold<int>(0, (sum, r) => sum + r.amountCents);
  final notes = <String>[];
  if (payments is List) {
    for (final item in payments) {
      if (item is Map && item['notes'] is String && '${item['notes']}'.isNotEmpty) {
        notes.add('${item['notes']}');
      }
    }
  }
  return PassageGroup(
    id: '${row['id']}',
    eventId: '${row['event_id']}',
    buyerName: '${row['buyer_name_snapshot'] ?? ''}',
    passengerIds: passengerIds,
    paidCents: paid,
    paymentMethod: records.isNotEmpty ? records.last.method : PaymentMethod.pix,
    receiptNotes: notes,
    createdAt: parseDate(row['created_at']) ?? DateTime.now(),
    deadlineBypass: row['deadline_bypass'] as bool? ?? false,
    paymentRecords: records,
  );
}

Allocation allocationFromRow(Map<String, dynamic> row) {
  final pd = row['passenger_days'];
  String passengerId = '';
  String dayId = '';
  if (pd is Map) {
    passengerId = '${pd['event_passenger_id'] ?? ''}';
    dayId = '${pd['event_day_id'] ?? ''}';
  }
  return Allocation(
    id: '${row['id']}',
    passengerId: passengerId,
    vehicleId: '${row['vehicle_id']}',
    dayId: dayId,
    position: (row['position'] as num?)?.toInt() ?? 0,
    status: allocationStatusFromPg(row['status']),
    relocatedToVehicleId: row['relocated_to_allocation_id'] == null
        ? null
        : '${row['target_vehicle_id'] ?? row['relocated_to_allocation_id']}',
    substitutePassengerId: row['replacement_passenger_id'] == null
        ? null
        : '${row['replacement_passenger_id']}',
    stopId: row['stop_id'] == null ? null : '${row['stop_id']}',
  );
}

CheckInRecord checkInFromRow(Map<String, dynamic> row) {
  return CheckInRecord(
    allocationId: '${row['passenger_allocation_id']}',
    direction: '${row['trip_direction'] ?? 'OUTBOUND'}',
    at: parseDate(row['checked_in_at']) ?? DateTime.now(),
  );
}

Map<String, dynamic> passengerDraftToRpc(PassengerDraft draft) {
  return {
    'id': draft.id,
    'name': draft.name,
    'document_type': draft.documentType,
    'document_number': draft.documentNumber,
    'birth_date': draft.birthDate?.toIso8601String().split('T').first,
    'category': pgPassengerCategory(draft.category),
    'responsible_name': draft.responsibleName,
    'day_ids': draft.dayIds,
  };
}
