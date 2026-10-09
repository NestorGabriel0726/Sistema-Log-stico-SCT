-- =====================================================================
-- SISTEMA DE GESTÃO LOGÍSTICA DE TRANSPORTE PARA ASSEMBLEIAS E CONGRESSOS
-- MIGRATION 20261009160000_initial_schema.sql
-- =====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
CREATE TYPE event_type AS ENUM (
    'CIRCUIT_ASSEMBLY',
    'REGIONAL_CONVENTION',
    'OTHER'
);

CREATE TYPE event_status AS ENUM (
    'DRAFT',
    'OPEN',
    'FINALIZED',
    'IN_PROGRESS',
    'COMPLETED',
    'ARCHIVED'
);

CREATE TYPE passenger_category AS ENUM (
    'ADULT',
    'STUDENT',
    'MINOR',
    'EXEMPT'
);

CREATE TYPE passenger_status AS ENUM (
    'ACTIVE',
    'CANCELLED'
);

CREATE TYPE passage_status AS ENUM (
    'ACTIVE',
    'CANCELLED'
);

CREATE TYPE payment_method AS ENUM (
    'PIX',
    'CASH'
);

CREATE TYPE vehicle_type AS ENUM (
    'BUS',
    'CAR'
);

CREATE TYPE vehicle_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);

CREATE TYPE allocation_status AS ENUM (
    'ACTIVE',
    'RELOCATED',
    'CANCELLED',
    'DESISTED'
);

CREATE TYPE trip_direction AS ENUM (
    'OUTBOUND',
    'RETURN'
);

CREATE TYPE invitation_role AS ENUM (
    'COORDINATOR',
    'COORDINATOR_HELPER',
    'BUS_CAPTAIN',
    'CAPTAIN_HELPER'
);

CREATE TYPE invitation_status AS ENUM (
    'PENDING',
    'ACCEPTED',
    'EXPIRED',
    'REVOKED'
);

CREATE TYPE member_role AS ENUM (
    'ADMIN',
    'COORDINATOR',
    'CAPTAIN',
    'MEMBER'
);

-- =====================================================================
-- 3. TABELAS DE AUTENTICAÇÃO, PERFIL E CONGREGAÇÃO
-- =====================================================================

-- Profiles (Vínculo direto com auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Congregações
CREATE TABLE public.congregations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country_code TEXT NOT NULL DEFAULT 'BR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Membros da Congregação
CREATE TABLE public.congregation_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    congregation_id UUID NOT NULL REFERENCES public.congregations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role member_role NOT NULL DEFAULT 'MEMBER',
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_congregation_user UNIQUE (congregation_id, user_id)
);

-- =====================================================================
-- 4. CADASTRO MESTRE DE PESSOAS
-- =====================================================================
CREATE TABLE public.people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    congregation_id UUID NOT NULL REFERENCES public.congregations(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    document_type TEXT CHECK (document_type IN ('RG', 'CPF', 'CERTIDAO', 'OTHER')),
    document_number TEXT,
    birth_date DATE,
    default_responsible_person_id UUID REFERENCES public.people(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 5. EVENTOS E ESTRUTURA DIÁRIA
-- =====================================================================
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    congregation_id UUID NOT NULL REFERENCES public.congregations(id) ON DELETE CASCADE,
    type event_type NOT NULL,
    theme TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'America/Bahia',
    currency_code TEXT NOT NULL DEFAULT 'BRL',
    daily_fare_cents INTEGER NOT NULL CHECK (daily_fare_cents >= 0),
    minimum_paying_age INTEGER NOT NULL DEFAULT 6 CHECK (minimum_paying_age >= 0),
    passage_deadline TIMESTAMPTZ,
    preliminary_list_deadline TIMESTAMPTZ,
    final_list_deadline TIMESTAMPTZ,
    status event_status NOT NULL DEFAULT 'DRAFT',
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT check_event_dates CHECK (end_date >= start_date)
);

CREATE TABLE public.event_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    event_date DATE NOT NULL,
    label TEXT NOT NULL,
    sequence_order INTEGER NOT NULL CHECK (sequence_order > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_event_day_date UNIQUE (event_id, event_date),
    CONSTRAINT unique_event_day_seq UNIQUE (event_id, sequence_order)
);

-- =====================================================================
-- 6. VEÍCULOS POR EVENTO
-- =====================================================================
CREATE TABLE public.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    type vehicle_type NOT NULL DEFAULT 'BUS',
    name TEXT NOT NULL,
    physical_capacity INTEGER NOT NULL CHECK (physical_capacity > 0),
    local_capacity INTEGER NOT NULL CHECK (local_capacity > 0 AND local_capacity <= physical_capacity),
    status vehicle_status NOT NULL DEFAULT 'ACTIVE',
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 7. EQUIPE DO EVENTO E PERMISSÕES EXPLÍCITAS
-- =====================================================================
CREATE TABLE public.event_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role invitation_role NOT NULL,
    assigned_vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_event_staff_user UNIQUE (event_id, user_id)
);

CREATE TABLE public.event_staff_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_staff_id UUID NOT NULL REFERENCES public.event_staff(id) ON DELETE CASCADE,
    permission TEXT NOT NULL,
    is_granted BOOLEAN NOT NULL DEFAULT true,
    granted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_staff_permission UNIQUE (event_staff_id, permission)
);

-- =====================================================================
-- 8. CONVITES PARA EVENTOS / CONGREGAÇÃO
-- =====================================================================
CREATE TABLE public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    congregation_id UUID NOT NULL REFERENCES public.congregations(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    role invitation_role NOT NULL,
    assigned_vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
    status invitation_status NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMPTZ NOT NULL,
    invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ
);

-- =====================================================================
-- 9. PASSAGEIROS DO EVENTO E DIAS DE PARTICIPAÇÃO
-- =====================================================================
CREATE TABLE public.event_passengers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE RESTRICT,
    full_name_snapshot TEXT NOT NULL,
    document_type_snapshot TEXT,
    document_number_snapshot TEXT,
    birth_date_snapshot DATE,
    category passenger_category NOT NULL DEFAULT 'ADULT',
    responsible_person_id UUID REFERENCES public.people(id) ON DELETE SET NULL,
    responsible_name_snapshot TEXT,
    status passenger_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_event_person UNIQUE (event_id, person_id)
);

CREATE TABLE public.passenger_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_passenger_id UUID NOT NULL REFERENCES public.event_passengers(id) ON DELETE CASCADE,
    event_day_id UUID NOT NULL REFERENCES public.event_days(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_passenger_day UNIQUE (event_passenger_id, event_day_id)
);

-- =====================================================================
-- 10. PASSAGENS (GRUPO FINANCEIRO) E PASSAGEIROS DA PASSAGEM
-- =====================================================================
CREATE TABLE public.passages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    buyer_person_id UUID NOT NULL REFERENCES public.people(id) ON DELETE RESTRICT,
    buyer_name_snapshot TEXT NOT NULL,
    status passage_status NOT NULL DEFAULT 'ACTIVE',
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.passage_passengers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passage_id UUID NOT NULL REFERENCES public.passages(id) ON DELETE CASCADE,
    event_passenger_id UUID NOT NULL REFERENCES public.event_passengers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_event_passenger_passage UNIQUE (event_passenger_id)
);

-- =====================================================================
-- 11. PAGAMENTOS E COMPROVANTES (STORAGE)
-- =====================================================================
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passage_id UUID NOT NULL REFERENCES public.passages(id) ON DELETE CASCADE,
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    payment_method payment_method NOT NULL,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    registered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.payment_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 12. ALOCAÇÃO OPERACIONAL EM VEÍCULOS POR DIA
-- =====================================================================
CREATE TABLE public.passenger_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_day_id UUID NOT NULL REFERENCES public.passenger_days(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position > 0),
    status allocation_status NOT NULL DEFAULT 'ACTIVE',
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    relocated_from_allocation_id UUID REFERENCES public.passenger_allocations(id) ON DELETE SET NULL,
    relocated_to_allocation_id UUID REFERENCES public.passenger_allocations(id) ON DELETE SET NULL,
    relocated_at TIMESTAMPTZ,
    relocated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    desisted_at TIMESTAMPTZ,
    desisted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    desisted_reason TEXT,
    replacement_passenger_id UUID REFERENCES public.event_passengers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Regra: Apenas 1 alocação ATIVA por passenger_day
CREATE UNIQUE INDEX idx_unique_active_passenger_day_allocation 
    ON public.passenger_allocations (passenger_day_id) 
    WHERE status = 'ACTIVE';

-- =====================================================================
-- 13. CHECK-IN DIÁRIO (IDA E VOLTA)
-- =====================================================================
CREATE TABLE public.check_ins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_day_id UUID NOT NULL REFERENCES public.event_days(id) ON DELETE CASCADE,
    passenger_allocation_id UUID NOT NULL REFERENCES public.passenger_allocations(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES public.event_passengers(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    trip_direction trip_direction NOT NULL,
    performed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_checkin_per_trip UNIQUE (passenger_allocation_id, trip_direction)
);

-- =====================================================================
-- 14. NOTIFICAÇÕES E DISPOSITIVOS
-- =====================================================================
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    entity_type TEXT,
    entity_id UUID,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.notification_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ANDROID', 'IOS', 'WEB', 'WINDOWS', 'MACOS')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_device_fcm UNIQUE (user_id, fcm_token)
);

-- =====================================================================
-- 15. AUDITORIA
-- =====================================================================
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    congregation_id UUID REFERENCES public.congregations(id) ON DELETE SET NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    actor_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_role TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    before_data JSONB,
    after_data JSONB,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 16. ÍNDICES DE PERFORMANCE
-- =====================================================================
CREATE INDEX idx_congregation_members_user ON public.congregation_members(user_id);
CREATE INDEX idx_events_congregation_date ON public.events(congregation_id, start_date);
CREATE INDEX idx_event_days_event_date ON public.event_days(event_id, event_date);
CREATE INDEX idx_event_passengers_event ON public.event_passengers(event_id);
CREATE INDEX idx_event_passengers_category ON public.event_passengers(event_id, category);
CREATE INDEX idx_passenger_days_passenger ON public.passenger_days(event_passenger_id);
CREATE INDEX idx_passenger_days_day ON public.passenger_days(event_day_id);
CREATE INDEX idx_passages_event ON public.passages(event_id);
CREATE INDEX idx_payments_passage ON public.payments(passage_id);
CREATE INDEX idx_vehicles_event ON public.vehicles(event_id);
CREATE INDEX idx_allocations_vehicle_status ON public.passenger_allocations(vehicle_id, status);
CREATE INDEX idx_allocations_passenger_day ON public.passenger_allocations(passenger_day_id);
CREATE INDEX idx_checkins_day_vehicle ON public.check_ins(event_day_id, vehicle_id);
CREATE INDEX idx_notifications_recipient_read ON public.notifications(recipient_user_id, read_at);
CREATE INDEX idx_audit_logs_event_created ON public.audit_logs(event_id, created_at);

-- =====================================================================
-- 17. FUNÇÕES AUXILIARES DE CÁLCULO E AUTORIZAÇÃO
-- =====================================================================

-- Cálculo de idade na data relevante (Regra de Ouro da Isenção)
CREATE OR REPLACE FUNCTION public.calculate_age_on_date(
    p_birth_date DATE,
    p_target_date DATE
) RETURNS INTEGER AS $$
BEGIN
    IF p_birth_date IS NULL OR p_target_date IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN date_part('year', age(p_target_date, p_birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Normalização de string para busca fonética/sem acento
CREATE OR REPLACE FUNCTION public.normalize_text(p_text TEXT) 
RETURNS TEXT AS $$
BEGIN
    IF p_text IS NULL THEN
        RETURN '';
    END IF;
    RETURN lower(translate(
        p_text,
        'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
        'aaaaaeeeeiiiiooooouuuucnaaaaaeeeeiiiiooooouuuucn'
    ));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Normalização automática em people
CREATE OR REPLACE FUNCTION public.trigger_normalize_people_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.normalized_name := public.normalize_text(NEW.full_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_normalize_people_name
    BEFORE INSERT OR UPDATE OF full_name ON public.people
    FOR EACH ROW EXECUTE FUNCTION public.trigger_normalize_people_name();

-- Trigger para sincronizar auth.users -> public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = CASE WHEN public.profiles.full_name = '' THEN EXCLUDED.full_name ELSE public.profiles.full_name END,
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =====================================================================
-- 18. FUNÇÕES DE AUTORIZAÇÃO PARA RLS
-- =====================================================================

CREATE OR REPLACE FUNCTION public.is_authenticated_user()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.uid() IS NOT NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION public.is_congregation_member(p_congregation_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.congregation_members
        WHERE congregation_id = p_congregation_id
          AND user_id = auth.uid()
          AND status = 'ACTIVE'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_event_coordinator(p_event_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.event_staff
        WHERE event_id = p_event_id
          AND user_id = auth.uid()
          AND role = 'COORDINATOR'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_event_member(p_event_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.event_staff
        WHERE event_id = p_event_id
          AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.has_event_permission(
    p_event_id UUID,
    p_permission TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_role invitation_role;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;

    -- Coordenador sempre possui autoridade máxima dentro do evento
    SELECT role INTO v_role
    FROM public.event_staff
    WHERE event_id = p_event_id AND user_id = auth.uid();

    IF v_role = 'COORDINATOR' THEN
        RETURN true;
    END IF;

    -- Verifica permissão explícita concedida
    RETURN EXISTS (
        SELECT 1 
        FROM public.event_staff es
        JOIN public.event_staff_permissions esp ON esp.event_staff_id = es.id
        WHERE es.event_id = p_event_id
          AND es.user_id = auth.uid()
          AND esp.permission = p_permission
          AND esp.is_granted = true
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_assigned_captain(
    p_event_id UUID,
    p_vehicle_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;

    -- Coordenador atua também com autoridade operacional
    IF public.is_event_coordinator(p_event_id) THEN
        RETURN true;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.event_staff
        WHERE event_id = p_event_id
          AND user_id = auth.uid()
          AND assigned_vehicle_id = p_vehicle_id
          AND role IN ('BUS_CAPTAIN', 'CAPTAIN_HELPER')
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- =====================================================================
-- 19. VIEWS ANALÍTICAS E OPERACIONAIS
-- =====================================================================

-- Resumo financeiro por passagem
CREATE OR REPLACE VIEW public.passage_financial_summary AS
SELECT 
    p.id AS passage_id,
    p.event_id,
    p.buyer_person_id,
    p.buyer_name_snapshot,
    p.status AS passage_status,
    p.created_at,
    e.daily_fare_cents,
    COUNT(pp.id) AS total_passengers,
    -- Soma do valor esperado de cada passageiro
    COALESCE(SUM(
        CASE 
            WHEN ep.category = 'EXEMPT' THEN 0
            ELSE (
                SELECT COUNT(pd.id) 
                FROM public.passenger_days pd 
                WHERE pd.event_passenger_id = ep.id
            ) * e.daily_fare_cents
        END
    ), 0)::INTEGER AS total_expected_cents,
    -- Soma dos pagamentos realizados
    COALESCE(pay.total_paid_cents, 0)::INTEGER AS total_paid_cents,
    -- Saldo pendente
    (
        COALESCE(SUM(
            CASE 
                WHEN ep.category = 'EXEMPT' THEN 0
                ELSE (
                    SELECT COUNT(pd.id) 
                    FROM public.passenger_days pd 
                    WHERE pd.event_passenger_id = ep.id
                ) * e.daily_fare_cents
            END
        ), 0) - COALESCE(pay.total_paid_cents, 0)
    )::INTEGER AS balance_cents,
    -- Status financeiro
    CASE 
        WHEN COALESCE(SUM(
            CASE 
                WHEN ep.category = 'EXEMPT' THEN 0
                ELSE (
                    SELECT COUNT(pd.id) 
                    FROM public.passenger_days pd 
                    WHERE pd.event_passenger_id = ep.id
                ) * e.daily_fare_cents
            END
        ), 0) = 0 THEN 'NOT_APPLICABLE'
        WHEN COALESCE(pay.total_paid_cents, 0) = 0 THEN 'UNPAID'
        WHEN COALESCE(pay.total_paid_cents, 0) < SUM(
            CASE 
                WHEN ep.category = 'EXEMPT' THEN 0
                ELSE (
                    SELECT COUNT(pd.id) 
                    FROM public.passenger_days pd 
                    WHERE pd.event_passenger_id = ep.id
                ) * e.daily_fare_cents
            END
        ) THEN 'PARTIALLY_PAID'
        WHEN COALESCE(pay.total_paid_cents, 0) = SUM(
            CASE 
                WHEN ep.category = 'EXEMPT' THEN 0
                ELSE (
                    SELECT COUNT(pd.id) 
                    FROM public.passenger_days pd 
                    WHERE pd.event_passenger_id = ep.id
                ) * e.daily_fare_cents
            END
        ) THEN 'PAID'
        ELSE 'OVERPAID'
    END AS financial_status
FROM public.passages p
JOIN public.events e ON e.id = p.event_id
LEFT JOIN public.passage_passengers pp ON pp.passage_id = p.id
LEFT JOIN public.event_passengers ep ON ep.id = pp.event_passenger_id
LEFT JOIN (
    SELECT passage_id, SUM(amount_cents) AS total_paid_cents
    FROM public.payments
    GROUP BY passage_id
) pay ON pay.passage_id = p.id
GROUP BY p.id, e.id, pay.total_paid_cents;

-- Resumo diário de lotação de veículos
CREATE OR REPLACE VIEW public.vehicle_daily_capacity_summary AS
SELECT 
    v.id AS vehicle_id,
    v.event_id,
    v.name AS vehicle_name,
    v.type AS vehicle_type,
    v.physical_capacity,
    v.local_capacity,
    ed.id AS event_day_id,
    ed.event_date,
    ed.label AS day_label,
    COUNT(pa.id) FILTER (WHERE pa.status = 'ACTIVE')::INTEGER AS active_allocations_count,
    (v.local_capacity - COUNT(pa.id) FILTER (WHERE pa.status = 'ACTIVE'))::INTEGER AS available_seats,
    CASE 
        WHEN COUNT(pa.id) FILTER (WHERE pa.status = 'ACTIVE') >= v.local_capacity THEN true
        ELSE false
    END AS is_full
FROM public.vehicles v
CROSS JOIN public.event_days ed
LEFT JOIN public.passenger_allocations pa 
    ON pa.vehicle_id = v.id 
   AND pa.passenger_day_id IN (
       SELECT pd.id 
       FROM public.passenger_days pd 
       WHERE pd.event_day_id = ed.id
   )
WHERE ed.event_id = v.event_id
GROUP BY v.id, ed.id;

-- Lista operacional para capitão (SEM DADOS FINANCEIROS)
CREATE OR REPLACE VIEW public.passenger_operational_list AS
SELECT 
    pa.id AS allocation_id,
    pa.position,
    pa.status AS allocation_status,
    ep.id AS event_passenger_id,
    ep.event_id,
    ep.full_name_snapshot AS passenger_name,
    ep.document_type_snapshot AS document_type,
    ep.document_number_snapshot AS document_number,
    ep.category,
    ep.responsible_name_snapshot AS responsible_name,
    v.id AS vehicle_id,
    v.name AS vehicle_name,
    ed.id AS event_day_id,
    ed.event_date,
    ed.label AS day_label,
    pa.relocated_from_allocation_id IS NOT NULL AS was_relocated,
    pa.desisted_at IS NOT NULL AS has_desisted,
    ci_out.checked_in_at IS NOT NULL AS outbound_checkin_done,
    ci_ret.checked_in_at IS NOT NULL AS return_checkin_done
FROM public.passenger_allocations pa
JOIN public.passenger_days pd ON pd.id = pa.passenger_day_id
JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
JOIN public.vehicles v ON v.id = pa.vehicle_id
JOIN public.event_days ed ON ed.id = pd.event_day_id
LEFT JOIN public.check_ins ci_out 
    ON ci_out.passenger_allocation_id = pa.id 
   AND ci_out.trip_direction = 'OUTBOUND'
LEFT JOIN public.check_ins ci_ret 
    ON ci_ret.passenger_allocation_id = pa.id 
   AND ci_ret.trip_direction = 'RETURN';

-- =====================================================================
-- 20. OPERAÇÕES TRANSACIONAIS DO BANCO (DATABASE RPC FUNCTIONS)
-- =====================================================================

-- 20.1 Alocar passageiro em um veículo e dia
CREATE OR REPLACE FUNCTION public.allocate_passenger(
    p_passenger_day_id UUID,
    p_vehicle_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_event_id UUID;
    v_vehicle_event_id UUID;
    v_local_capacity INTEGER;
    v_current_active_count INTEGER;
    v_next_position INTEGER;
    v_allocation_id UUID;
    v_caller_role TEXT;
    v_passenger_name TEXT;
    v_vehicle_name TEXT;
BEGIN
    -- Validar autenticação
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Validar passenger_day e evento correspondente
    SELECT ep.event_id, ep.full_name_snapshot
    INTO v_event_id, v_passenger_name
    FROM public.passenger_days pd
    JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
    WHERE pd.id = p_passenger_day_id;

    IF v_event_id IS NULL THEN
        RAISE EXCEPTION 'PASSENGER_NOT_FOUND';
    END IF;

    -- Validar veículo e garantir mesmo evento (Regra de Integridade 86)
    SELECT v.event_id, v.local_capacity, v.name
    INTO v_vehicle_event_id, v_local_capacity, v_vehicle_name
    FROM public.vehicles v
    WHERE v.id = p_vehicle_id;

    IF v_vehicle_event_id IS NULL OR v_vehicle_event_id <> v_event_id THEN
        RAISE EXCEPTION 'VEHICLE_NOT_FOUND';
    END IF;

    -- Validar permissão: Coordenador ou Capitão autorizado a editar lista
    IF NOT public.has_event_permission(v_event_id, 'edit_passenger_list') AND 
       NOT public.is_event_coordinator(v_event_id) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Bloquear concorrente: lock no veículo para cálculo atômico de vagas
    PERFORM 1 FROM public.vehicles WHERE id = p_vehicle_id FOR UPDATE;

    -- Verificar vagas ativas no dia/veículo
    SELECT COUNT(*)
    INTO v_current_active_count
    FROM public.passenger_allocations pa
    JOIN public.passenger_days pd ON pd.id = pa.passenger_day_id
    WHERE pa.vehicle_id = p_vehicle_id
      AND pa.status = 'ACTIVE'
      AND pd.event_day_id = (SELECT event_day_id FROM public.passenger_days WHERE id = p_passenger_day_id);

    IF v_current_active_count >= v_local_capacity THEN
        RAISE EXCEPTION 'VEHICLE_FULL';
    END IF;

    -- Verificar se já existe alocação ATIVA para este passenger_day
    IF EXISTS (
        SELECT 1 FROM public.passenger_allocations 
        WHERE passenger_day_id = p_passenger_day_id AND status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'PASSENGER_ALREADY_ALLOCATED';
    END IF;

    -- Determinar próxima posição
    SELECT COALESCE(MAX(position), 0) + 1
    INTO v_next_position
    FROM public.passenger_allocations
    WHERE vehicle_id = p_vehicle_id
      AND passenger_day_id IN (
          SELECT id FROM public.passenger_days 
          WHERE event_day_id = (SELECT event_day_id FROM public.passenger_days WHERE id = p_passenger_day_id)
      );

    -- Inserir alocação
    INSERT INTO public.passenger_allocations (
        passenger_day_id,
        vehicle_id,
        position,
        status,
        assigned_by
    ) VALUES (
        p_passenger_day_id,
        p_vehicle_id,
        v_next_position,
        'ACTIVE',
        auth.uid()
    ) RETURNING id INTO v_allocation_id;

    -- Identificar papel do ator para auditoria
    SELECT role::TEXT INTO v_caller_role
    FROM public.event_staff
    WHERE event_id = v_event_id AND user_id = auth.uid();

    -- Registrar Auditoria Obrigatória
    INSERT INTO public.audit_logs (
        event_id,
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        v_event_id,
        auth.uid(),
        v_caller_role,
        'ALLOCATE_PASSENGER',
        'passenger_allocations',
        v_allocation_id,
        jsonb_build_object(
            'passenger_day_id', p_passenger_day_id,
            'vehicle_id', p_vehicle_id,
            'position', v_next_position
        ),
        jsonb_build_object(
            'passenger_name', v_passenger_name,
            'vehicle_name', v_vehicle_name
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'allocation_id', v_allocation_id,
        'position', v_next_position
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 20.2 Realocar passageiro (Atômico: origem liberada + destino ocupado sem race condition)
CREATE OR REPLACE FUNCTION public.relocate_passenger(
    p_current_allocation_id UUID,
    p_target_vehicle_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_old_alloc public.passenger_allocations%ROWTYPE;
    v_passenger_day_id UUID;
    v_event_id UUID;
    v_event_day_id UUID;
    v_target_capacity INTEGER;
    v_target_active_count INTEGER;
    v_next_position INTEGER;
    v_new_allocation_id UUID;
    v_caller_role TEXT;
    v_passenger_name TEXT;
    v_source_vehicle_name TEXT;
    v_target_vehicle_name TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Obter alocação atual com lock
    SELECT * INTO v_old_alloc
    FROM public.passenger_allocations
    WHERE id = p_current_allocation_id
    FOR UPDATE;

    IF v_old_alloc.id IS NULL OR v_old_alloc.status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'ALLOCATION_NOT_FOUND_OR_INACTIVE';
    END IF;

    IF v_old_alloc.vehicle_id = p_target_vehicle_id THEN
        RAISE EXCEPTION 'CANNOT_RELOCATE_TO_SAME_VEHICLE';
    END IF;

    -- Metadados do passageiro e dia
    SELECT ep.event_id, ep.full_name_snapshot, pd.event_day_id
    INTO v_event_id, v_passenger_name, v_event_day_id
    FROM public.passenger_days pd
    JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
    WHERE pd.id = v_old_alloc.passenger_day_id;

    -- Nome veículo de origem
    SELECT name INTO v_source_vehicle_name FROM public.vehicles WHERE id = v_old_alloc.vehicle_id;

    -- Validar permissão
    IF NOT public.has_event_permission(v_event_id, 'edit_passenger_list') AND 
       NOT public.is_event_coordinator(v_event_id) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Lock no veículo destino e verificar capacidade
    SELECT local_capacity, name INTO v_target_capacity, v_target_vehicle_name
    FROM public.vehicles
    WHERE id = p_target_vehicle_id AND event_id = v_event_id
    FOR UPDATE;

    IF v_target_capacity IS NULL THEN
        RAISE EXCEPTION 'VEHICLE_NOT_FOUND';
    END IF;

    SELECT COUNT(*) INTO v_target_active_count
    FROM public.passenger_allocations pa
    JOIN public.passenger_days pd ON pd.id = pa.passenger_day_id
    WHERE pa.vehicle_id = p_target_vehicle_id
      AND pa.status = 'ACTIVE'
      AND pd.event_day_id = v_event_day_id;

    IF v_target_active_count >= v_target_capacity THEN
        RAISE EXCEPTION 'VEHICLE_FULL';
    END IF;

    -- Próxima posição no destino
    SELECT COALESCE(MAX(position), 0) + 1
    INTO v_next_position
    FROM public.passenger_allocations pa
    JOIN public.passenger_days pd ON pd.id = pa.passenger_day_id
    WHERE pa.vehicle_id = p_target_vehicle_id
      AND pd.event_day_id = v_event_day_id;

    -- Criar nova alocação no veículo de destino
    INSERT INTO public.passenger_allocations (
        passenger_day_id,
        vehicle_id,
        position,
        status,
        assigned_by,
        relocated_from_allocation_id
    ) VALUES (
        v_old_alloc.passenger_day_id,
        p_target_vehicle_id,
        v_next_position,
        'ACTIVE',
        auth.uid(),
        v_old_alloc.id
    ) RETURNING id INTO v_new_allocation_id;

    -- Atualizar alocação antiga (permanece no histórico, mas com status RELOCATED)
    UPDATE public.passenger_allocations
    SET status = 'RELOCATED',
        relocated_to_allocation_id = v_new_allocation_id,
        relocated_at = now(),
        relocated_by = auth.uid()
    WHERE id = v_old_alloc.id;

    -- Identificar papel para auditoria
    SELECT role::TEXT INTO v_caller_role
    FROM public.event_staff
    WHERE event_id = v_event_id AND user_id = auth.uid();

    -- Registrar auditoria
    INSERT INTO public.audit_logs (
        event_id,
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        before_data,
        after_data,
        metadata
    ) VALUES (
        v_event_id,
        auth.uid(),
        v_caller_role,
        'RELOCATE_PASSENGER',
        'passenger_allocations',
        v_new_allocation_id,
        jsonb_build_object(
            'old_allocation_id', v_old_alloc.id,
            'source_vehicle_id', v_old_alloc.vehicle_id,
            'source_vehicle_name', v_source_vehicle_name
        ),
        jsonb_build_object(
            'new_allocation_id', v_new_allocation_id,
            'target_vehicle_id', p_target_vehicle_id,
            'target_vehicle_name', v_target_vehicle_name,
            'position', v_next_position
        ),
        jsonb_build_object(
            'passenger_name', v_passenger_name
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'new_allocation_id', v_new_allocation_id,
        'position', v_next_position
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 20.3 Registrar desistência (Libera vaga e preserva no histórico)
CREATE OR REPLACE FUNCTION public.mark_passenger_desisted(
    p_allocation_id UUID,
    p_reason TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_alloc public.passenger_allocations%ROWTYPE;
    v_event_id UUID;
    v_caller_role TEXT;
    v_passenger_name TEXT;
    v_vehicle_name TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    SELECT * INTO v_alloc
    FROM public.passenger_allocations
    WHERE id = p_allocation_id
    FOR UPDATE;

    IF v_alloc.id IS NULL OR v_alloc.status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'ALLOCATION_NOT_FOUND_OR_INACTIVE';
    END IF;

    SELECT ep.event_id, ep.full_name_snapshot, v.name
    INTO v_event_id, v_passenger_name, v_vehicle_name
    FROM public.passenger_days pd
    JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
    JOIN public.vehicles v ON v.id = v_alloc.vehicle_id
    WHERE pd.id = v_alloc.passenger_day_id;

    IF NOT public.has_event_permission(v_event_id, 'edit_passenger_list') AND 
       NOT public.is_event_coordinator(v_event_id) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Atualizar para DESISTED
    UPDATE public.passenger_allocations
    SET status = 'DESISTED',
        desisted_at = now(),
        desisted_by = auth.uid(),
        desisted_reason = p_reason
    WHERE id = p_allocation_id;

    SELECT role::TEXT INTO v_caller_role
    FROM public.event_staff
    WHERE event_id = v_event_id AND user_id = auth.uid();

    INSERT INTO public.audit_logs (
        event_id,
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        v_event_id,
        auth.uid(),
        v_caller_role,
        'MARK_DESISTED',
        'passenger_allocations',
        p_allocation_id,
        jsonb_build_object(
            'status', 'DESISTED',
            'reason', p_reason
        ),
        jsonb_build_object(
            'passenger_name', v_passenger_name,
            'vehicle_name', v_vehicle_name
        )
    );

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 20.4 Check-in diário (Ida / Volta)
CREATE OR REPLACE FUNCTION public.perform_checkin(
    p_allocation_id UUID,
    p_trip_direction trip_direction
) RETURNS JSONB AS $$
DECLARE
    v_alloc public.passenger_allocations%ROWTYPE;
    v_event_id UUID;
    v_event_day_id UUID;
    v_passenger_id UUID;
    v_checkin_id UUID;
    v_passenger_name TEXT;
    v_caller_role TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    SELECT * INTO v_alloc
    FROM public.passenger_allocations
    WHERE id = p_allocation_id;

    IF v_alloc.id IS NULL OR v_alloc.status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'CHECKIN_NOT_ALLOWED_INACTIVE_ALLOCATION';
    END IF;

    SELECT ep.event_id, ep.id, ep.full_name_snapshot, pd.event_day_id
    INTO v_event_id, v_passenger_id, v_passenger_name, v_event_day_id
    FROM public.passenger_days pd
    JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
    WHERE pd.id = v_alloc.passenger_day_id;

    -- Validar permissão de checkin
    IF NOT public.has_event_permission(v_event_id, 'perform_checkin') AND 
       NOT public.is_event_coordinator(v_event_id) THEN
        RAISE EXCEPTION 'CHECKIN_NOT_ALLOWED';
    END IF;

    -- Inserir ou atualizar check-in
    INSERT INTO public.check_ins (
        event_day_id,
        passenger_allocation_id,
        passenger_id,
        vehicle_id,
        trip_direction,
        performed_by,
        checked_in_at
    ) VALUES (
        v_event_day_id,
        v_alloc.id,
        v_passenger_id,
        v_alloc.vehicle_id,
        p_trip_direction,
        auth.uid(),
        now()
    ) RETURNING id INTO v_checkin_id;

    SELECT role::TEXT INTO v_caller_role
    FROM public.event_staff
    WHERE event_id = v_event_id AND user_id = auth.uid();

    INSERT INTO public.audit_logs (
        event_id,
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        v_event_id,
        auth.uid(),
        v_caller_role,
        'PERFORM_CHECKIN',
        'check_ins',
        v_checkin_id,
        jsonb_build_object(
            'passenger_id', v_passenger_id,
            'direction', p_trip_direction
        ),
        jsonb_build_object(
            'passenger_name', v_passenger_name
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'checkin_id', v_checkin_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 20.5 Registrar Pagamento (Atômico com auditoria financeira)
CREATE OR REPLACE FUNCTION public.record_payment(
    p_passage_id UUID,
    p_amount_cents INTEGER,
    p_payment_method payment_method,
    p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_event_id UUID;
    v_payment_id UUID;
    v_buyer_name TEXT;
    v_caller_role TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    IF p_amount_cents <= 0 THEN
        RAISE EXCEPTION 'INVALID_AMOUNT';
    END IF;

    SELECT event_id, buyer_name_snapshot
    INTO v_event_id, v_buyer_name
    FROM public.passages
    WHERE id = p_passage_id;

    IF v_event_id IS NULL THEN
        RAISE EXCEPTION 'PASSAGE_NOT_FOUND';
    END IF;

    -- Apenas Coordenador ou Ajudante com permissão manage_payments
    IF NOT public.has_event_permission(v_event_id, 'manage_payments') AND 
       NOT public.is_event_coordinator(v_event_id) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    INSERT INTO public.payments (
        passage_id,
        amount_cents,
        payment_method,
        paid_at,
        registered_by,
        notes
    ) VALUES (
        p_passage_id,
        p_amount_cents,
        p_payment_method,
        now(),
        auth.uid(),
        p_notes
    ) RETURNING id INTO v_payment_id;

    SELECT role::TEXT INTO v_caller_role
    FROM public.event_staff
    WHERE event_id = v_event_id AND user_id = auth.uid();

    INSERT INTO public.audit_logs (
        event_id,
        actor_user_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        v_event_id,
        auth.uid(),
        v_caller_role,
        'RECORD_PAYMENT',
        'payments',
        v_payment_id,
        jsonb_build_object(
            'amount_cents', p_amount_cents,
            'method', p_payment_method
        ),
        jsonb_build_object(
            'buyer_name', v_buyer_name
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'payment_id', v_payment_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =====================================================================
-- 21. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================

-- Ativar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.congregations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.congregation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_staff_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passenger_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passage_passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passenger_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 21.1 Profiles
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    USING (public.is_authenticated_user());

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

-- 21.2 Congregations
CREATE POLICY "Members can view their congregations"
    ON public.congregations FOR SELECT
    USING (public.is_congregation_member(id));

-- 21.3 Congregation Members
CREATE POLICY "Members can view congregation members"
    ON public.congregation_members FOR SELECT
    USING (public.is_congregation_member(congregation_id));

-- 21.4 People
CREATE POLICY "Congregation members can view people in congregation"
    ON public.people FOR SELECT
    USING (public.is_congregation_member(congregation_id));

CREATE POLICY "Congregation members can insert/update people in congregation"
    ON public.people FOR ALL
    USING (public.is_congregation_member(congregation_id));

-- 21.5 Events & Days
CREATE POLICY "Members of congregation can view events"
    ON public.events FOR SELECT
    USING (public.is_congregation_member(congregation_id));

CREATE POLICY "Coordinators can manage events"
    ON public.events FOR ALL
    USING (public.is_event_coordinator(id) OR public.is_congregation_member(congregation_id));

CREATE POLICY "Anyone who can view event can view its days"
    ON public.event_days FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_days.event_id AND public.is_congregation_member(e.congregation_id)));

-- 21.6 Vehicles
CREATE POLICY "Event staff can view vehicles"
    ON public.vehicles FOR SELECT
    USING (public.is_event_member(event_id));

CREATE POLICY "Staff with manage_vehicles can manage vehicles"
    ON public.vehicles FOR ALL
    USING (public.is_event_coordinator(event_id) OR public.has_event_permission(event_id, 'manage_vehicles'));

-- 21.7 Event Staff & Permissions
CREATE POLICY "Event staff can view staff of their event"
    ON public.event_staff FOR SELECT
    USING (public.is_event_member(event_id));

CREATE POLICY "Event coordinator can manage staff"
    ON public.event_staff FOR ALL
    USING (public.is_event_coordinator(event_id));

CREATE POLICY "Staff can view permissions of their event"
    ON public.event_staff_permissions FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.event_staff es WHERE es.id = event_staff_permissions.event_staff_id AND public.is_event_member(es.event_id)));

CREATE POLICY "Coordinator can manage permissions"
    ON public.event_staff_permissions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.event_staff es WHERE es.id = event_staff_permissions.event_staff_id AND public.is_event_coordinator(es.event_id)));

-- 21.8 Invitations
CREATE POLICY "Users can view invitations addressed to their email"
    ON public.invitations FOR SELECT
    USING (email = (SELECT email FROM public.profiles WHERE id = auth.uid()) OR public.is_event_coordinator(event_id));

-- 21.9 Event Passengers & Passenger Days
CREATE POLICY "Event staff can view event passengers"
    ON public.event_passengers FOR SELECT
    USING (public.is_event_member(event_id));

CREATE POLICY "Staff with manage_passengers can manage passengers"
    ON public.event_passengers FOR ALL
    USING (public.is_event_coordinator(event_id) OR public.has_event_permission(event_id, 'manage_passengers'));

CREATE POLICY "Event staff can view passenger days"
    ON public.passenger_days FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.event_passengers ep WHERE ep.id = passenger_days.event_passenger_id AND public.is_event_member(ep.event_id)));

-- 21.10 Passages & Passage Passengers (DADOS FINANCEIROS PROTEGIDOS - Seção 32, 58, 141)
CREATE POLICY "Authorized staff can view passages"
    ON public.passages FOR SELECT
    USING (
        public.is_event_coordinator(event_id) OR 
        public.has_event_permission(event_id, 'view_financial_data')
    );

CREATE POLICY "Authorized staff can manage passages"
    ON public.passages FOR ALL
    USING (
        public.is_event_coordinator(event_id) OR 
        public.has_event_permission(event_id, 'manage_passages')
    );

CREATE POLICY "Authorized staff can view passage passengers"
    ON public.passage_passengers FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.passages p WHERE p.id = passage_passengers.passage_id AND (public.is_event_coordinator(p.event_id) OR public.has_event_permission(p.event_id, 'view_financial_data'))));

-- 21.11 Payments & Payment Receipts (BLOQUEIO TOTAL PARA CAPITÃO - Seção 32, 58, 141, 142)
CREATE POLICY "Only financial staff can view payments"
    ON public.payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.passages p
            WHERE p.id = payments.passage_id
              AND (public.is_event_coordinator(p.event_id) OR public.has_event_permission(p.event_id, 'view_financial_data'))
        )
    );

CREATE POLICY "Only financial staff can manage payments"
    ON public.payments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.passages p
            WHERE p.id = payments.passage_id
              AND (public.is_event_coordinator(p.event_id) OR public.has_event_permission(p.event_id, 'manage_payments'))
        )
    );

CREATE POLICY "Only financial staff can view receipts"
    ON public.payment_receipts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.payments pay
            JOIN public.passages p ON p.id = pay.passage_id
            WHERE pay.id = payment_receipts.payment_id
              AND (public.is_event_coordinator(p.event_id) OR public.has_event_permission(p.event_id, 'view_receipts'))
        )
    );

-- 21.12 Allocations & Check-ins
CREATE POLICY "Event staff can view allocations"
    ON public.passenger_allocations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.passenger_days pd
            JOIN public.event_passengers ep ON ep.id = pd.event_passenger_id
            WHERE pd.id = passenger_allocations.passenger_day_id
              AND public.is_event_member(ep.event_id)
        )
    );

CREATE POLICY "Event staff can view check-ins"
    ON public.check_ins FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.event_days ed
            WHERE ed.id = check_ins.event_day_id
              AND public.is_event_member(ed.event_id)
        )
    );

-- 21.13 Notifications & Devices
CREATE POLICY "Users can view and manage their own notifications"
    ON public.notifications FOR ALL
    USING (recipient_user_id = auth.uid());

CREATE POLICY "Users can manage their own notification devices"
    ON public.notification_devices FOR ALL
    USING (user_id = auth.uid());

-- 21.14 Audit Logs
CREATE POLICY "Authorized staff can view audit logs"
    ON public.audit_logs FOR SELECT
    USING (
        event_id IS NULL OR 
        public.is_event_coordinator(event_id) OR 
        public.has_event_permission(event_id, 'view_audit_log')
    );

-- =====================================================================
-- 22. REALTIME CONFIGURATION
-- =====================================================================
-- Habilitar publicação realtime para tabelas operacionais sincronizadas
ALTER PUBLICATION supabase_realtime ADD TABLE public.passenger_allocations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.check_ins;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.vehicles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_passengers;
