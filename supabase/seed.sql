-- =====================================================================
-- SISTEMA DE GESTÃO LOGÍSTICA DE TRANSPORTE PARA ASSEMBLEIAS E CONGRESSOS
-- SEED DATA: supabase/seed.sql (DADOS DE TESTE FICTÍCIOS - SEÇÃO 97)
-- =====================================================================

-- 1. IDs FIXOS PARA TESTES REPRODUZÍVEIS
DO $$
DECLARE
    -- Usuários / Perfis
    v_user_coord UUID := '11111111-1111-1111-1111-111111111111';
    v_user_coord_helper UUID := '22222222-2222-2222-2222-222222222222';
    v_user_captain_1 UUID := '33333333-3333-3333-3333-333333333333';
    v_user_captain_2 UUID := '44444444-4444-4444-4444-444444444444';
    v_user_captain_helper_1 UUID := '55555555-5555-5555-5555-555555555555';
    v_user_captain_helper_2 UUID := '66666666-6666-6666-6666-666666666666';

    -- Congregação
    v_congregation_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    -- Evento (Congresso de 3 dias)
    v_event_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_day_1_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0001';
    v_day_2_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0002';
    v_day_3_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0003';

    -- Veículos (3 veículos: 2 Ônibus e 1 Carro)
    v_bus_1_id UUID := 'cccccccc-cccc-cccc-cccc-cccccccc0001';
    v_bus_2_id UUID := 'cccccccc-cccc-cccc-cccc-cccccccc0002';
    v_car_1_id UUID := 'cccccccc-cccc-cccc-cccc-cccccccc0003';

    -- Pessoas Mestres
    v_person_adult_1 UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0001';
    v_person_adult_2 UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0002';
    v_person_child_exempt UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0003'; -- Menor de 6 anos (Isento)
    v_person_child_paying UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0004'; -- Maior de 6 anos (Pagante)
    v_person_student UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0005';
    v_person_substitute UUID := 'dddddddd-dddd-dddd-dddd-dddddddd0006';

    -- Event Passengers
    v_ep_adult_1 UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0001';
    v_ep_adult_2 UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0002';
    v_ep_child_exempt UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0003';
    v_ep_child_paying UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0004';
    v_ep_student UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0005';
    v_ep_substitute UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0006';

    -- Passenger Days
    v_pd_adult_1_d1 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0101';
    v_pd_adult_1_d2 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0102';
    v_pd_adult_1_d3 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0103';

    v_pd_adult_2_d1 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0201';
    v_pd_adult_2_d2 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0202';

    v_pd_child_exempt_d1 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0301';
    v_pd_child_exempt_d2 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0302';
    v_pd_child_exempt_d3 UUID := 'ffffffff-ffff-ffff-ffff-ffffffff0303';

    -- Passagens
    v_passage_1 UUID := '10101010-1010-1010-1010-101010101010';
    v_passage_2 UUID := '20202020-2020-2020-2020-202020202020';

    -- Alocações
    v_alloc_adult_1_d1 UUID := '90909090-9090-9090-9090-909090900101';
    v_alloc_adult_2_d1 UUID := '90909090-9090-9090-9090-909090900201';
    v_alloc_reloc_old UUID := '90909090-9090-9090-9090-909090900301';
    v_alloc_reloc_new UUID := '90909090-9090-9090-9090-909090900302';
    v_alloc_desisted UUID := '90909090-9090-9090-9090-909090900401';
BEGIN

    -- 1. PROFILES (auth.users mock via profiles)
    INSERT INTO public.profiles (id, email, full_name) VALUES
        (v_user_coord, 'coordenador@exemplo.com', 'Carlos Coordenador'),
        (v_user_coord_helper, 'ajudante.coord@exemplo.com', 'Lucas Ajudante Coordenador'),
        (v_user_captain_1, 'capitao1@exemplo.com', 'Marcos Capitão Ônibus 1'),
        (v_user_captain_2, 'capitao2@exemplo.com', 'Daniel Capitão Ônibus 2'),
        (v_user_captain_helper_1, 'ajudante.cap1@exemplo.com', 'Pedro Ajudante Capitão 1'),
        (v_user_captain_helper_2, 'ajudante.cap2@exemplo.com', 'Tiago Ajudante Capitão 2')
    ON CONFLICT (id) DO NOTHING;

    -- 2. CONGREGAÇÃO
    INSERT INTO public.congregations (id, name, code, city, state) VALUES
        (v_congregation_id, 'Congregação Central', 'BR-BA-001', 'Salvador', 'BA')
    ON CONFLICT DO NOTHING;

    -- 3. MEMBROS DA CONGREGAÇÃO
    INSERT INTO public.congregation_members (congregation_id, user_id, role, status) VALUES
        (v_congregation_id, v_user_coord, 'COORDINATOR', 'ACTIVE'),
        (v_congregation_id, v_user_coord_helper, 'MEMBER', 'ACTIVE'),
        (v_congregation_id, v_user_captain_1, 'CAPTAIN', 'ACTIVE'),
        (v_congregation_id, v_user_captain_2, 'CAPTAIN', 'ACTIVE'),
        (v_congregation_id, v_user_captain_helper_1, 'MEMBER', 'ACTIVE'),
        (v_congregation_id, v_user_captain_helper_2, 'MEMBER', 'ACTIVE')
    ON CONFLICT DO NOTHING;

    -- 4. CADASTRO MESTRE DE PESSOAS
    INSERT INTO public.people (id, congregation_id, full_name, normalized_name, document_type, document_number, birth_date) VALUES
        (v_person_adult_1, v_congregation_id, 'João da Silva', 'joao da silva', 'CPF', '111.222.333-44', '1985-05-15'),
        (v_person_adult_2, v_congregation_id, 'Maria de Oliveira', 'maria de oliveira', 'RG', '1234567-SSP', '1988-08-20'),
        (v_person_child_exempt, v_congregation_id, 'Enzo Gabriel da Silva', 'enzo gabriel da silva', 'CERTIDAO', '987654321', '2022-03-10'), -- 4 anos em 2026 (Isento)
        (v_person_child_paying, v_congregation_id, 'Larissa de Oliveira', 'larissa de oliveira', 'RG', '5544332-SSP', '2019-01-12'), -- 7 anos em 2026 (Pagante)
        (v_person_student, v_congregation_id, 'Felipe dos Santos', 'felipe dos santos', 'CPF', '444.555.666-77', '2005-11-25'),
        (v_person_substitute, v_congregation_id, 'Roberto Albuquerque', 'roberto albuquerque', 'CPF', '777.888.999-00', '1990-04-05')
    ON CONFLICT DO NOTHING;

    -- 5. EVENTO (Congresso Regional de 3 dias - 2026-10-16 a 2026-10-18)
    INSERT INTO public.events (
        id, congregation_id, type, theme, start_date, end_date, timezone, currency_code, 
        daily_fare_cents, minimum_paying_age, passage_deadline, status, created_by
    ) VALUES (
        v_event_id, v_congregation_id, 'REGIONAL_CONVENTION', 'Declare as Boas Novas! 2026', 
        '2026-10-16', '2026-10-18', 'America/Bahia', 'BRL', 
        5000, -- R$ 50,00 por dia
        6,    -- Isenção para menores de 6 anos
        '2026-10-10 23:59:59-03', 'OPEN', v_user_coord
    ) ON CONFLICT DO NOTHING;

    -- 6. DIAS DO EVENTO
    INSERT INTO public.event_days (id, event_id, event_date, label, sequence_order) VALUES
        (v_day_1_id, v_event_id, '2026-10-16', 'Sexta-feira', 1),
        (v_day_2_id, v_event_id, '2026-10-17', 'Sábado', 2),
        (v_day_3_id, v_event_id, '2026-10-18', 'Domingo', 3)
    ON CONFLICT DO NOTHING;

    -- 7. VEÍCULOS
    INSERT INTO public.vehicles (id, event_id, type, name, physical_capacity, local_capacity, status, created_by) VALUES
        (v_bus_1_id, v_event_id, 'BUS', 'Ônibus 01 (Convencional)', 46, 30, 'ACTIVE', v_user_coord),
        (v_bus_2_id, v_event_id, 'BUS', 'Ônibus 02 (Executivo)', 46, 32, 'ACTIVE', v_user_coord),
        (v_car_1_id, v_event_id, 'CAR', 'Carro de Apoio 01', 5, 4, 'ACTIVE', v_user_coord)
    ON CONFLICT DO NOTHING;

    -- 8. EQUIPE DO EVENTO E PERMISSÕES
    INSERT INTO public.event_staff (event_id, user_id, role, assigned_vehicle_id) VALUES
        (v_event_id, v_user_coord, 'COORDINATOR', NULL),
        (v_event_id, v_user_coord_helper, 'COORDINATOR_HELPER', NULL),
        (v_event_id, v_user_captain_1, 'BUS_CAPTAIN', v_bus_1_id),
        (v_event_id, v_user_captain_2, 'BUS_CAPTAIN', v_bus_2_id),
        (v_event_id, v_user_captain_helper_1, 'CAPTAIN_HELPER', v_bus_1_id),
        (v_event_id, v_user_captain_helper_2, 'CAPTAIN_HELPER', v_bus_2_id)
    ON CONFLICT DO NOTHING;

    -- Permissões explícitas para Ajudante do Coordenador (inclui financeiro)
    INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
    SELECT es.id, p.perm, true
    FROM public.event_staff es
    CROSS JOIN (VALUES 
        ('view_event'), ('manage_passages'), ('manage_passengers'), 
        ('view_financial_data'), ('manage_payments'), ('view_receipts'),
        ('perform_checkin'), ('edit_passenger_list')
    ) AS p(perm)
    WHERE es.event_id = v_event_id AND es.user_id = v_user_coord_helper
    ON CONFLICT DO NOTHING;

    -- Permissões para Capitão 1 (apenas operacional + check-in, SEM FINANCEIRO)
    INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
    SELECT es.id, p.perm, true
    FROM public.event_staff es
    CROSS JOIN (VALUES 
        ('view_event'), ('perform_checkin'), ('edit_passenger_list')
    ) AS p(perm)
    WHERE es.event_id = v_event_id AND es.user_id = v_user_captain_1
    ON CONFLICT DO NOTHING;

    -- 9. PASSAGEIROS NO EVENTO
    INSERT INTO public.event_passengers (
        id, event_id, person_id, full_name_snapshot, document_type_snapshot, document_number_snapshot, 
        birth_date_snapshot, category, responsible_person_id, responsible_name_snapshot, status
    ) VALUES
        (v_ep_adult_1, v_event_id, v_person_adult_1, 'João da Silva', 'CPF', '111.222.333-44', '1985-05-15', 'ADULT', NULL, NULL, 'ACTIVE'),
        (v_ep_adult_2, v_event_id, v_person_adult_2, 'Maria de Oliveira', 'RG', '1234567-SSP', '1988-08-20', 'ADULT', NULL, NULL, 'ACTIVE'),
        (v_ep_child_exempt, v_event_id, v_person_child_exempt, 'Enzo Gabriel da Silva', 'CERTIDAO', '987654321', '2022-03-10', 'EXEMPT', v_person_adult_1, 'João da Silva', 'ACTIVE'),
        (v_ep_child_paying, v_event_id, v_person_child_paying, 'Larissa de Oliveira', 'RG', '5544332-SSP', '2019-01-12', 'MINOR', v_person_adult_2, 'Maria de Oliveira', 'ACTIVE'),
        (v_ep_student, v_event_id, v_person_student, 'Felipe dos Santos', 'CPF', '444.555.666-77', '2005-11-25', 'STUDENT', NULL, NULL, 'ACTIVE'),
        (v_ep_substitute, v_event_id, v_person_substitute, 'Roberto Albuquerque', 'CPF', '777.888.999-00', '1990-04-05', 'ADULT', NULL, NULL, 'ACTIVE')
    ON CONFLICT DO NOTHING;

    -- 10. DIAS DE PARTICIPAÇÃO
    -- João: 3 dias (3x50 = R$ 150)
    INSERT INTO public.passenger_days (id, event_passenger_id, event_day_id) VALUES
        (v_pd_adult_1_d1, v_ep_adult_1, v_day_1_id),
        (v_pd_adult_1_d2, v_ep_adult_1, v_day_2_id),
        (v_pd_adult_1_d3, v_ep_adult_1, v_day_3_id)
    ON CONFLICT DO NOTHING;

    -- Enzo (Isento): 3 dias (Isento = R$ 0)
    INSERT INTO public.passenger_days (id, event_passenger_id, event_day_id) VALUES
        (v_pd_child_exempt_d1, v_ep_child_exempt, v_day_1_id),
        (v_pd_child_exempt_d2, v_ep_child_exempt, v_day_2_id),
        (v_pd_child_exempt_d3, v_ep_child_exempt, v_day_3_id)
    ON CONFLICT DO NOTHING;

    -- Maria: 2 dias (2x50 = R$ 100)
    INSERT INTO public.passenger_days (id, event_passenger_id, event_day_id) VALUES
        (v_pd_adult_2_d1, v_ep_adult_2, v_day_1_id),
        (v_pd_adult_2_d2, v_ep_adult_2, v_day_2_id)
    ON CONFLICT DO NOTHING;

    -- 11. PASSAGENS (GRUPO FINANCEIRO)
    -- Passagem 1: Comprador João (João + Enzo Isento). Total esperado: R$ 150.
    INSERT INTO public.passages (id, event_id, buyer_person_id, buyer_name_snapshot, created_by) VALUES
        (v_passage_1, v_event_id, v_person_adult_1, 'João da Silva', v_user_coord)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.passage_passengers (passage_id, event_passenger_id) VALUES
        (v_passage_1, v_ep_adult_1),
        (v_passage_1, v_ep_child_exempt)
    ON CONFLICT DO NOTHING;

    -- Passagem 2: Comprador Maria. Total esperado: R$ 100.
    INSERT INTO public.passages (id, event_id, buyer_person_id, buyer_name_snapshot, created_by) VALUES
        (v_passage_2, v_event_id, v_person_adult_2, 'Maria de Oliveira', v_user_coord)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.passage_passengers (passage_id, event_passenger_id) VALUES
        (v_passage_2, v_ep_adult_2)
    ON CONFLICT DO NOTHING;

    -- 12. PAGAMENTOS (CASOS: TOTALMENTE PAGO E PARCIALMENTE PAGO)
    -- Passagem 1: Paga integralmente via PIX (R$ 150 = 15000 centavos)
    INSERT INTO public.payments (passage_id, amount_cents, payment_method, registered_by, notes) VALUES
        (v_passage_1, 15000, 'PIX', v_user_coord, 'Pagamento PIX confirmado com comprovante')
    ON CONFLICT DO NOTHING;

    -- Passagem 2: Pagamento PARCIAL (Esperado: R$ 100, Pago: R$ 50 = 5000 centavos)
    INSERT INTO public.payments (passage_id, amount_cents, payment_method, registered_by, notes) VALUES
        (v_passage_2, 5000, 'CASH', v_user_coord_helper, 'Entrada de R$ 50,00 em dinheiro. Saldo pendente: R$ 50,00.')
    ON CONFLICT DO NOTHING;

    -- 13. ALOCAÇÕES EM VEÍCULOS
    -- João no Ônibus 1 na Sexta-feira
    INSERT INTO public.passenger_allocations (id, passenger_day_id, vehicle_id, position, status, assigned_by) VALUES
        (v_alloc_adult_1_d1, v_pd_adult_1_d1, v_bus_1_id, 1, 'ACTIVE', v_user_coord)
    ON CONFLICT DO NOTHING;

    -- Maria no Ônibus 2 na Sexta-feira
    INSERT INTO public.passenger_allocations (id, passenger_day_id, vehicle_id, position, status, assigned_by) VALUES
        (v_alloc_adult_2_d1, v_pd_adult_2_d1, v_bus_2_id, 1, 'ACTIVE', v_user_coord)
    ON CONFLICT DO NOTHING;

    -- Caso de REALOCAÇÃO: Enzo veio do Ônibus 2 e foi realocado para Ônibus 1 (Sexta-feira)
    INSERT INTO public.passenger_allocations (
        id, passenger_day_id, vehicle_id, position, status, assigned_by, relocated_to_allocation_id, relocated_at, relocated_by
    ) VALUES (
        v_alloc_reloc_old, v_pd_child_exempt_d1, v_bus_2_id, 2, 'RELOCATED', v_user_coord, v_alloc_reloc_new, now() - interval '2 hours', v_user_coord
    ) ON CONFLICT DO NOTHING;

    INSERT INTO public.passenger_allocations (
        id, passenger_day_id, vehicle_id, position, status, assigned_by, relocated_from_allocation_id
    ) VALUES (
        v_alloc_reloc_new, v_pd_child_exempt_d1, v_bus_1_id, 2, 'ACTIVE', v_user_coord, v_alloc_reloc_old
    ) ON CONFLICT DO NOTHING;

    -- 14. CHECK-IN REALIZADO
    -- Check-in de IDA feito para João na Sexta-feira
    INSERT INTO public.check_ins (event_day_id, passenger_allocation_id, passenger_id, vehicle_id, trip_direction, performed_by) VALUES
        (v_day_1_id, v_alloc_adult_1_d1, v_ep_adult_1, v_bus_1_id, 'OUTBOUND', v_user_captain_1)
    ON CONFLICT DO NOTHING;

    -- 15. CONVITES DE TESTE (FASE 1)
    INSERT INTO public.invitations (
        email, congregation_id, event_id, role, assigned_vehicle_id, status, expires_at, invited_by
    ) VALUES 
        ('convidado.capitao@exemplo.com', v_congregation_id, v_event_id, 'BUS_CAPTAIN', v_bus_1_id, 'PENDING', now() + interval '7 days', v_user_coord),
        ('convidado.expirado@exemplo.com', v_congregation_id, v_event_id, 'CAPTAIN_HELPER', v_bus_1_id, 'EXPIRED', now() - interval '1 day', v_user_coord),
        ('convidado.revogado@exemplo.com', v_congregation_id, v_event_id, 'BUS_CAPTAIN', v_bus_2_id, 'REVOKED', now() + interval '5 days', v_user_coord)
    ON CONFLICT DO NOTHING;

    -- 16. AUDITORIA INICIAL
    INSERT INTO public.audit_logs (event_id, actor_user_id, actor_role, action, entity_type, entity_id, after_data, metadata) VALUES
        (v_event_id, v_user_coord, 'COORDINATOR', 'SEED_INITIALIZED', 'events', v_event_id, jsonb_build_object('theme', 'Declare as Boas Novas! 2026'), jsonb_build_object('system', 'seed.sql'));

END $$;
