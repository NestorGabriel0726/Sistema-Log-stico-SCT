import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_logistics/data/local_app_store.dart';
import 'package:transport_logistics/data/seed_data.dart';
import 'package:transport_logistics/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  LocalAppStore signedStore() {
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);
    return store;
  }

  test('seed, check-in e desistência liberam vaga', () {
    final store = signedStore();

    expect(store.listEvents().single.id, SeedData.eventId);
    expect(store.passengersForEvent(SeedData.eventId).length, 6);

    final result = store.performCheckIn('a1', 'OUTBOUND');
    expect(result.ok, isTrue);
    expect(store.hasCheckIn('a1', 'OUTBOUND'), isTrue);

    final before =
        store.allocationsForVehicleDay('bus-1', 'day-1').where((a) => a.isActive).length;
    store.markDesisted(allocationId: 'a1');
    final after =
        store.allocationsForVehicleDay('bus-1', 'day-1').where((a) => a.isActive).length;
    expect(after, before - 1);
  });

  test('isenção inválida é recusada na passagem', () {
    final store = signedStore();
    final event = store.eventById(SeedData.eventId)!;
    final err = store.validateExemption(
      category: PassengerCategory.exempt,
      birthDate: DateTime(2018, 1, 1),
      event: event,
    );
    expect(err, isNotNull);
  });

  group('integridade de dias do evento', () {
    test('preserva IDs de dias cujas datas continuam no intervalo', () {
      final store = signedStore();
      final before = store.daysForEvent(SeedData.eventId);
      final idDay1 = before.firstWhere((d) => d.id == 'day-1').id;
      final idDay2 = before.firstWhere((d) => d.id == 'day-2').id;
      final event = store.eventById(SeedData.eventId)!;

      // Amplia o período: dias 16–18 permanecem; 19 é novo.
      final result = store.updateEvent(
        event.copyWith(
          startDate: DateTime(2026, 10, 16),
          endDate: DateTime(2026, 10, 19),
        ),
      );
      expect(result.ok, isTrue);

      final after = store.daysForEvent(SeedData.eventId);
      expect(after.length, 4);
      expect(after.firstWhere((d) => d.date.day == 16).id, idDay1);
      expect(after.firstWhere((d) => d.date.day == 17).id, idDay2);
      expect(after.any((d) => d.date.day == 19), isTrue);
      expect(after.where((d) => d.date.day == 19).single.id, isNot(anyOf(idDay1, idDay2, 'day-3')));
    });

    test('bloqueia remoção de dia com passageiros ou alocações', () {
      final store = signedStore();
      final event = store.eventById(SeedData.eventId)!;
      final day1Before = store.daysForEvent(SeedData.eventId).map((d) => d.id).toSet();

      // Tenta encolher para só domingo (18) — remove sex/sáb com dependências.
      final result = store.updateEvent(
        event.copyWith(
          startDate: DateTime(2026, 10, 18),
          endDate: DateTime(2026, 10, 18),
        ),
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('Não é possível remover'));

      final day1After = store.daysForEvent(SeedData.eventId).map((d) => d.id).toSet();
      expect(day1After, day1Before);
      expect(store.eventById(SeedData.eventId)!.startDate, DateTime(2026, 10, 16));
    });

    test('permite remover dia sem dependências', () {
      final store = signedStore();
      // Cria evento novo sem passageiros e depois reduz dias.
      final created = store.createEvent(
        theme: 'Evento limpo',
        kind: EventKind.other,
        start: DateTime(2027, 1, 1),
        end: DateTime(2027, 1, 3),
        dailyFareCents: 1000,
      );
      expect(created.ok, isTrue);
      final eventId = created.message;
      final event = store.eventById(eventId)!;
      final days = store.daysForEvent(eventId);
      expect(days.length, 3);

      final shrunk = store.updateEvent(
        event.copyWith(
          startDate: DateTime(2027, 1, 2),
          endDate: DateTime(2027, 1, 3),
        ),
      );
      expect(shrunk.ok, isTrue);
      final after = store.daysForEvent(eventId);
      expect(after.length, 2);
      expect(after.map((d) => d.date.day).toSet(), {2, 3});
    });
  });

  group('updatePassage', () {
    test('atualiza campos editáveis e preserva id e pagamentos', () {
      final store = signedStore();
      final original = store.passageById('pass-1')!;
      final paidBefore = original.paidCents;
      final notesBefore = List<String>.from(original.receiptNotes);
      final createdAt = original.createdAt;
      final expectedBefore = store.expectedCentsForPassage(original);

      final p1 = store.passengerById('p1')!;
      final p3 = store.passengerById('p3')!;

      final result = store.updatePassage(
        passageId: 'pass-1',
        eventId: SeedData.eventId,
        buyerName: 'Ana Silva Atualizada',
        method: PaymentMethod.cash,
        passengers: [
          PassengerDraft(
            id: p1.id,
            name: p1.name,
            documentType: p1.documentType,
            documentNumber: p1.documentNumber,
            category: p1.category,
            dayIds: ['day-1', 'day-2'], // remove day-3 → esperado cai
          ),
          PassengerDraft(
            id: p3.id,
            name: p3.name,
            documentType: p3.documentType,
            documentNumber: p3.documentNumber,
            birthDate: p3.birthDate,
            category: p3.category,
            responsibleName: p3.responsibleName,
            dayIds: p3.dayIds,
          ),
        ],
      );

      expect(result.ok, isTrue);
      final updated = store.passageById('pass-1')!;
      expect(updated.id, 'pass-1');
      expect(updated.buyerName, 'Ana Silva Atualizada');
      expect(updated.paymentMethod, PaymentMethod.cash);
      expect(updated.paidCents, paidBefore);
      expect(updated.receiptNotes, notesBefore);
      expect(updated.createdAt, createdAt);
      expect(store.passengerById('p1')!.dayIds, ['day-1', 'day-2']);

      final expectedAfter = store.expectedCentsForPassage(updated);
      expect(expectedAfter, lessThan(expectedBefore));
      expect(expectedAfter, 10000); // 2 dias × 50 para Ana; Lucas isento
    });

    test('addPayment soma sem confundir com edição', () {
      final store = signedStore();
      final before = store.passageById('pass-3')!.paidCents;
      final pay = store.addPayment(
        passageId: 'pass-3',
        extraCents: 2500,
        method: PaymentMethod.pix,
        receiptNote: 'PIX extra',
      );
      expect(pay.ok, isTrue);
      expect(store.passageById('pass-3')!.paidCents, before + 2500);
      expect(store.passageById('pass-3')!.receiptNotes, contains('PIX extra'));
      expect(store.passageById('pass-3')!.paymentRecords.length, 1);
      expect(store.passageById('pass-3')!.paymentRecords.first.method, PaymentMethod.pix);
      expect(store.passageById('pass-3')!.paymentRecords.first.amountCents, 2500);

      final edit = store.updatePassage(
        passageId: 'pass-3',
        eventId: SeedData.eventId,
        buyerName: 'Daniel Oliveira Editado',
        method: PaymentMethod.pix,
        passengers: [
          PassengerDraft(
            id: 'p4',
            name: 'Daniel Oliveira',
            category: PassengerCategory.adult,
            dayIds: ['day-1'],
          ),
        ],
      );
      expect(edit.ok, isTrue);
      expect(store.passageById('pass-3')!.paidCents, before + 2500);
      expect(store.passageById('pass-3')!.receiptNotes, contains('PIX extra'));
      expect(store.passageById('pass-3')!.buyerName, 'Daniel Oliveira Editado');
    });

    test('falha ao editar passagem inexistente', () {
      final store = signedStore();
      final result = store.updatePassage(
        passageId: 'nao-existe',
        eventId: SeedData.eventId,
        buyerName: 'X',
        method: PaymentMethod.pix,
        passengers: [
          PassengerDraft(name: 'Y', dayIds: ['day-1']),
        ],
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('não encontrada'));
    });

    test('falha se passagem não pertence ao evento', () {
      final store = signedStore();
      final result = store.updatePassage(
        passageId: 'pass-1',
        eventId: 'outro-evento',
        buyerName: 'Ana',
        method: PaymentMethod.pix,
        passengers: [
          PassengerDraft(id: 'p1', name: 'Ana Silva', dayIds: ['day-1']),
        ],
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('não pertence'));
    });

    test('persiste edição após hydrate', () async {
      SharedPreferences.setMockInitialValues({});
      final store = signedStore();
      final edit = store.updatePassage(
        passageId: 'pass-2',
        eventId: SeedData.eventId,
        buyerName: 'Bruno Persistido',
        method: PaymentMethod.pix,
        passengers: [
          PassengerDraft(
            id: 'p2',
            name: 'Bruno Costa',
            documentType: 'RG',
            documentNumber: '12.345.678-9',
            category: PassengerCategory.adult,
            dayIds: ['day-1', 'day-2'],
          ),
        ],
      );
      expect(edit.ok, isTrue);
      await store.flushPersist();
      expect(store.lastPersistError, isNull);

      final reloaded = LocalAppStore();
      await reloaded.hydrate();
      expect(reloaded.passageById('pass-2')!.buyerName, 'Bruno Persistido');
      expect(reloaded.passageById('pass-2')!.paidCents, 5000);
    });
  });

  group('persistência', () {
    test('registra erro quando a gravação falha', () async {
      final store = signedStore();
      await store.flushPersist();

      store.failNextPersist = true;
      store.signOut();
      await store.flushPersist();
      expect(store.lastPersistError, isNotNull);
      expect(store.lastPersistError, contains('salvar'));

      store.clearPersistError();
      expect(store.lastPersistError, isNull);

      // Próxima gravação bem-sucedida limpa o estado.
      store.signIn(name: 'Carlos', role: UserRole.coordinator);
      await store.flushPersist();
      expect(store.lastPersistError, isNull);
    });

    test('JSON corrompido no storage bloqueia sobrescrita e preserva arquivo original e backup', () async {
      SharedPreferences.setMockInitialValues({
        'sct_local_state_v2': '{este json esta completamente corrompido!!!',
      });
      final store = LocalAppStore();
      await store.hydrate();

      expect(store.storageCorrupted, isTrue);
      expect(store.persistenceBlocked, isTrue);
      expect(store.lastPersistError, contains('bloqueada'));
      expect(store.loadErrors, isNotEmpty);
      expect(store.listEvents(), isEmpty); // Não mascara com SeedData

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sct_local_state_v2_backup'), '{este json esta completamente corrompido!!!');

      // Tenta alterar dados (ex: login ou edição) — a gravação deve ser bloqueada
      store.signIn(name: 'Tentativa De Login', role: UserRole.coordinator);
      await store.flushPersist();

      expect(store.lastPersistError, contains('bloqueada'));
      // O dado no SharedPreferences NÃO foi sobrescrito!
      expect(prefs.getString('sct_local_state_v2'), '{este json esta completamente corrompido!!!');
    });

    test('JSON com campos ausentes ou nulos recupera com segurança sem descartar dados', () async {
      SharedPreferences.setMockInitialValues({
        'sct_local_state_v2': jsonEncode({
          'events': [
            {
              'id': 'ev-recuperado',
              'theme': 'Evento Parcial Recuperado',
            }
          ],
          'passengers': [
            {
              'id': 'p-rec',
              'eventId': 'ev-recuperado',
              'name': 'Passageiro Sem Categoria',
            }
          ],
        }),
      });
      final store = LocalAppStore();
      await store.hydrate();

      expect(store.eventById('ev-recuperado')?.theme, 'Evento Parcial Recuperado');
      final p = store.passengerById('p-rec');
      expect(p, isNotNull);
      expect(p!.name, 'Passageiro Sem Categoria');
      expect(p.category, PassengerCategory.adult); // Fallback seguro
      expect(p.dayIds, isEmpty); // Fallback seguro
      expect(store.persistenceBlocked, isFalse);
    });

    test('item inválido na lista registra erro explícito e bloqueia gravação contra perda silenciosa', () async {
      SharedPreferences.setMockInitialValues({
        'sct_local_state_v2': jsonEncode({
          'events': 'isso nao e uma lista de eventos',
        }),
      });
      final store = LocalAppStore();
      await store.hydrate();

      expect(store.storageCorrupted, isTrue);
      expect(store.persistenceBlocked, isTrue);
      expect(store.loadErrors, isNotEmpty);
      expect(store.loadErrors.any((e) => e.contains('events')), isTrue);
      expect(store.lastPersistError, contains('bloqueada'));
    });

    test('resetDemo desbloqueia persistência e re-aplica seed', () async {
      SharedPreferences.setMockInitialValues({
        'sct_local_state_v2': '{corrompido}',
      });
      final store = LocalAppStore();
      await store.hydrate();
      expect(store.persistenceBlocked, isTrue);

      await store.resetDemo();
      expect(store.persistenceBlocked, isFalse);
      expect(store.storageCorrupted, isFalse);
      expect(store.listEvents().single.id, SeedData.eventId);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sct_local_state_v2'), isNot('{corrompido}'));
    });

    test('unblockPersistence limpa bloqueio de gravação', () async {
      SharedPreferences.setMockInitialValues({
        'sct_local_state_v2': '{corrompido}',
      });
      final store = LocalAppStore();
      await store.hydrate();
      expect(store.persistenceBlocked, isTrue);

      store.unblockPersistence();
      expect(store.persistenceBlocked, isFalse);
      expect(store.storageCorrupted, isFalse);
      expect(store.lastPersistError, isNull);
    });
  });

  group('financeSummaryByMethod', () {
    test('totais corretos com PIX e Espécie do seed', () {
      final store = signedStore();
      // pass-1: PIX R\$150, pass-2: Espécie R\$50, pass-3/5: sem pagamento, pass-4: PIX R\$50
      // pass-1 tem paymentRecords=[{150,pix}], pass-2=[{50,cash}], pass-4=[{50,pix}]
      // pass-3 e pass-5 têm paidCents=0 → não aparecem
      final s = store.financeSummaryByMethod(SeedData.eventId);
      expect(s.pixCents, 15000 + 5000); // pass-1 + pass-4
      expect(s.cashCents, 5000); // pass-2
      expect(s.unknownCents, 0); // seed novo tem paymentRecords
      expect(s.totalCents, 25000);
    });

    test('pagamentos parciais acumulam por método', () {
      final store = signedStore();
      // Adiciona dois pagamentos parciais com métodos diferentes à pass-3
      store.addPayment(
        passageId: 'pass-3',
        extraCents: 3000,
        method: PaymentMethod.pix,
        receiptNote: 'PIX parcial',
      );
      store.addPayment(
        passageId: 'pass-3',
        extraCents: 2000,
        method: PaymentMethod.cash,
        receiptNote: 'Espécie complemento',
      );

      final pass = store.passageById('pass-3')!;
      expect(pass.paidCents, 5000); // soma total
      expect(pass.paymentRecords.length, 2);

      final s = store.financeSummaryByMethod(SeedData.eventId);
      // PIX do seed (15000+5000) + 3000 da pass-3 = 23000
      expect(s.pixCents, 15000 + 5000 + 3000);
      // Espécie do seed (5000) + 2000 da pass-3 = 7000
      expect(s.cashCents, 5000 + 2000);
    });

    test('passagens sem paymentRecords ficam em unknownCents', () {
      // Simula passagem antiga: cria manualmente sem paymentRecords
      final store = signedStore();
      // Verifica que pass-3 do seed (paidCents=0) não inflaciona
      // Adiciona pagamento novo com método → vai para pixCents
      store.addPayment(
        passageId: 'pass-3',
        extraCents: 1000,
        method: PaymentMethod.cash,
      );
      final s = store.financeSummaryByMethod(SeedData.eventId);
      expect(s.unknownCents, 0); // Nenhuma passagem antiga sem paymentRecords
      expect(s.cashCents, 5000 + 1000); // seed pass-2 + novo
    });

    test('evento diferente não interfere nos totais', () {
      final store = signedStore();
      final sA = store.financeSummaryByMethod(SeedData.eventId);
      final sB = store.financeSummaryByMethod('evento-inexistente');
      expect(sB.totalCents, 0);
      expect(sA.totalCents, greaterThan(0));
    });
  });
}
