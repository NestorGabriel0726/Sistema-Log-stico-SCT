import '../domain/models.dart';

class SeedData {
  static const eventId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  static final demoEvent = TransportEvent(
    id: eventId,
    theme: 'Declare as Boas Novas! 2026',
    kind: EventKind.regionalConvention,
    lifecycle: EventLifecycle.open,
    startDate: DateTime(2026, 10, 16),
    endDate: DateTime(2026, 10, 18),
    dailyFareCents: 5000,
    minimumPayingAge: 6,
    passageDeadline: DateTime(2026, 10, 10),
    preliminaryListDeadline: DateTime(2026, 10, 12),
    finalListDeadline: DateTime(2026, 10, 15),
    captainCheckinEnabled: true,
    helperCheckinEnabled: false,
  );

  static final days = <EventDay>[
    EventDay(id: 'day-1', eventId: eventId, date: DateTime(2026, 10, 16), label: 'Sexta-feira'),
    EventDay(id: 'day-2', eventId: eventId, date: DateTime(2026, 10, 17), label: 'Sábado'),
    EventDay(id: 'day-3', eventId: eventId, date: DateTime(2026, 10, 18), label: 'Domingo'),
  ];

  static final vehicles = <Vehicle>[
    Vehicle(
      id: 'bus-1',
      eventId: eventId,
      name: 'Ônibus 01',
      type: VehicleType.bus,
      physicalCapacity: 46,
      localCapacity: 30,
    ),
    Vehicle(
      id: 'bus-2',
      eventId: eventId,
      name: 'Ônibus 02',
      type: VehicleType.bus,
      physicalCapacity: 46,
      localCapacity: 32,
    ),
    Vehicle(
      id: 'car-1',
      eventId: eventId,
      name: 'Carro equipe',
      type: VehicleType.car,
      physicalCapacity: 5,
      localCapacity: 4,
    ),
  ];

  static final passengers = <Passenger>[
    Passenger(
      id: 'p1',
      eventId: eventId,
      passageId: 'pass-1',
      name: 'Ana Silva',
      documentType: 'CPF',
      documentNumber: '123.456.789-00',
      category: PassengerCategory.adult,
      dayIds: ['day-1', 'day-2', 'day-3'],
    ),
    Passenger(
      id: 'p2',
      eventId: eventId,
      passageId: 'pass-2',
      name: 'Bruno Costa',
      documentType: 'RG',
      documentNumber: '12.345.678-9',
      category: PassengerCategory.adult,
      dayIds: ['day-1', 'day-2'],
    ),
    Passenger(
      id: 'p3',
      eventId: eventId,
      passageId: 'pass-1',
      name: 'Lucas Santos',
      documentType: 'Certidão',
      documentNumber: '12345',
      birthDate: DateTime(2021, 3, 10),
      category: PassengerCategory.exempt,
      responsibleName: 'Ana Silva',
      dayIds: ['day-1', 'day-2', 'day-3'],
    ),
    Passenger(
      id: 'p4',
      eventId: eventId,
      passageId: 'pass-3',
      name: 'Daniel Oliveira',
      category: PassengerCategory.adult,
      dayIds: ['day-1'],
    ),
    Passenger(
      id: 'p5',
      eventId: eventId,
      passageId: 'pass-4',
      name: 'Elena Ferreira',
      documentType: 'CPF',
      documentNumber: '987.654.321-00',
      category: PassengerCategory.student,
      responsibleName: 'Maria Ferreira',
      dayIds: ['day-2', 'day-3'],
    ),
    Passenger(
      id: 'p6',
      eventId: eventId,
      passageId: 'pass-5',
      name: 'Felipe Souza',
      category: PassengerCategory.adult,
      dayIds: ['day-3'],
    ),
  ];

  static final allocations = <Allocation>[
    Allocation(id: 'a1', passengerId: 'p1', vehicleId: 'bus-1', dayId: 'day-1', position: 1),
    Allocation(id: 'a2', passengerId: 'p2', vehicleId: 'bus-1', dayId: 'day-1', position: 2),
    Allocation(id: 'a3', passengerId: 'p4', vehicleId: 'bus-2', dayId: 'day-1', position: 1),
    Allocation(id: 'a4', passengerId: 'p1', vehicleId: 'bus-1', dayId: 'day-2', position: 1),
    Allocation(id: 'a5', passengerId: 'p5', vehicleId: 'bus-2', dayId: 'day-2', position: 1),
  ];

  static final passages = <PassageGroup>[
    PassageGroup(
      id: 'pass-1',
      eventId: eventId,
      buyerName: 'Ana Silva',
      passengerIds: ['p1', 'p3'],
      paidCents: 15000,
      paymentMethod: PaymentMethod.pix,
      receiptNotes: ['PIX Banco do Brasil 12/10'],
      createdAt: DateTime(2026, 10, 8, 10),
      paymentRecords: [PaymentRecord(amountCents: 15000, method: PaymentMethod.pix)],
    ),
    PassageGroup(
      id: 'pass-2',
      eventId: eventId,
      buyerName: 'Bruno Costa',
      passengerIds: ['p2'],
      paidCents: 5000,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime(2026, 10, 8, 11),
      paymentRecords: [PaymentRecord(amountCents: 5000, method: PaymentMethod.cash)],
    ),
    PassageGroup(
      id: 'pass-3',
      eventId: eventId,
      buyerName: 'Daniel Oliveira',
      passengerIds: ['p4'],
      paidCents: 0,
      createdAt: DateTime(2026, 10, 9, 9),
    ),
    PassageGroup(
      id: 'pass-4',
      eventId: eventId,
      buyerName: 'Maria Ferreira',
      passengerIds: ['p5'],
      paidCents: 5000,
      paymentMethod: PaymentMethod.pix,
      createdAt: DateTime(2026, 10, 9, 15),
      paymentRecords: [PaymentRecord(amountCents: 5000, method: PaymentMethod.pix)],
    ),
    PassageGroup(
      id: 'pass-5',
      eventId: eventId,
      buyerName: 'Felipe Souza',
      passengerIds: ['p6'],
      paidCents: 0,
      createdAt: DateTime(2026, 10, 9, 18),
    ),
  ];

  static final people = <PersonMemory>[
    const PersonMemory(
      fullName: 'Ana Silva',
      documentType: 'CPF',
      documentNumber: '123.456.789-00',
    ),
    const PersonMemory(
      fullName: 'Bruno Costa',
      documentType: 'RG',
      documentNumber: '12.345.678-9',
    ),
  ];

  static final activities = <ActivityEntry>[
    ActivityEntry(
      id: 'act-1',
      eventId: eventId,
      message: 'Evento criado com dados de demonstração.',
      at: DateTime(2026, 10, 1, 8),
      actorName: 'Sistema',
    ),
  ];
}
