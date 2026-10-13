-- =====================================================================
-- SISTEMA DE GESTÃO LOGÍSTICA DE TRANSPORTE PARA ASSEMBLEIAS E CONGRESSOS
-- MIGRATION 20261013160000_phase1_auth_invitations.sql
-- FASE 1: Autenticação, Usuários, Congregações, Memberships e Convites
-- =====================================================================

-- 1. TRIGGER PARA CRIAÇÃO AUTOMÁTICA DE PERFIL EM AUTH.USERS
-- Corrige a lacuna da Fase 0 onde handle_new_user() existia sem trigger associado.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_raw_name TEXT;
    v_avatar TEXT;
BEGIN
    -- Extrair nome com fallback seguro
    v_raw_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(COALESCE(NEW.email, ''), '@', 1)
    );

    -- Extrair avatar com fallback seguro (Google OAuth usa 'picture' ou 'avatar_url')
    v_avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture'
    );

    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        lower(trim(COALESCE(NEW.email, ''))),
        COALESCE(v_raw_name, ''),
        v_avatar
    )
    ON CONFLICT (id) DO UPDATE SET
        email = lower(trim(EXCLUDED.email)),
        full_name = CASE 
            WHEN public.profiles.full_name = '' OR public.profiles.full_name IS NULL 
            THEN EXCLUDED.full_name 
            ELSE public.profiles.full_name 
        END,
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE OF email, raw_user_meta_data ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. FUNÇÃO IDEMPOTENTE PARA GARANTIR PERFIL DO USUÁRIO LOGADO
CREATE OR REPLACE FUNCTION public.ensure_profile_exists()
RETURNS public.profiles AS $$
DECLARE
    v_profile public.profiles;
    v_user_email TEXT;
    v_user_name TEXT;
    v_user_avatar TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Obter metadados de auth.users
    SELECT 
        lower(trim(COALESCE(email, ''))),
        COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(COALESCE(email, ''), '@', 1)),
        COALESCE(raw_user_meta_data->>'avatar_url', raw_user_meta_data->>'picture')
    INTO v_user_email, v_user_name, v_user_avatar
    FROM auth.users
    WHERE id = auth.uid();

    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        auth.uid(),
        COALESCE(v_user_email, ''),
        COALESCE(v_user_name, ''),
        v_user_avatar
    )
    ON CONFLICT (id) DO UPDATE SET
        email = lower(trim(EXCLUDED.email)),
        full_name = CASE 
            WHEN public.profiles.full_name = '' OR public.profiles.full_name IS NULL 
            THEN EXCLUDED.full_name 
            ELSE public.profiles.full_name 
        END,
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = now()
    RETURNING * INTO v_profile;

    RETURN v_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. RLS POLICIES REFINADAS PARA PROFILES, CONGREGATION_MEMBERS E INVITATIONS

-- Profiles: Permitir insert próprio e manter update restrito
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Congregation Members: Usuário pode sempre ver seu próprio membership
DROP POLICY IF EXISTS "Members can view congregation members" ON public.congregation_members;
CREATE POLICY "Members can view congregation members"
    ON public.congregation_members FOR SELECT
    USING (
        user_id = auth.uid() 
        OR public.is_congregation_member(congregation_id)
    );

-- Invitations: Comparação de e-mail normalizada e suporte a Coordenadores de Congregação
DROP POLICY IF EXISTS "Users can view invitations addressed to their email" ON public.invitations;
CREATE POLICY "Users can view invitations addressed to their email"
    ON public.invitations FOR SELECT
    USING (
        lower(trim(email)) = lower(trim((SELECT email FROM public.profiles WHERE id = auth.uid())))
        OR (event_id IS NOT NULL AND public.is_event_coordinator(event_id))
        OR (EXISTS (
            SELECT 1 FROM public.congregation_members cm 
            WHERE cm.congregation_id = invitations.congregation_id 
              AND cm.user_id = auth.uid() 
              AND cm.role IN ('ADMIN', 'COORDINATOR') 
              AND cm.status = 'ACTIVE'
        ))
    );

-- 4. FUNÇÃO RPC: CRIAR CONVITE (COM VALIDAÇÃO DE AUTORIZAÇÃO E TRANSAÇÃO)
CREATE OR REPLACE FUNCTION public.create_invitation(
    p_email TEXT,
    p_congregation_id UUID,
    p_event_id UUID DEFAULT NULL,
    p_role invitation_role DEFAULT 'BUS_CAPTAIN',
    p_assigned_vehicle_id UUID DEFAULT NULL,
    p_expires_in_days INTEGER DEFAULT 7
) RETURNS JSONB AS $$
DECLARE
    v_clean_email TEXT;
    v_invitation_id UUID;
    v_is_authorized BOOLEAN := false;
    v_event_congregation_id UUID;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Validar autenticação
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Normalizar e validar e-mail
    v_clean_email := lower(trim(p_email));
    IF v_clean_email = '' OR position('@' in v_clean_email) = 0 THEN
        RAISE EXCEPTION 'INVALID_EMAIL';
    END IF;

    -- Validar congregação
    IF NOT EXISTS (SELECT 1 FROM public.congregations WHERE id = p_congregation_id) THEN
        RAISE EXCEPTION 'CONGREGATION_NOT_FOUND';
    END IF;

    -- Validar evento se especificado
    IF p_event_id IS NOT NULL THEN
        SELECT congregation_id INTO v_event_congregation_id
        FROM public.events
        WHERE id = p_event_id;

        IF v_event_congregation_id IS NULL OR v_event_congregation_id <> p_congregation_id THEN
            RAISE EXCEPTION 'EVENT_NOT_FOUND';
        END IF;

        -- Apenas Coordenador do Evento pode criar convites vinculados ao evento
        IF public.is_event_coordinator(p_event_id) THEN
            v_is_authorized := true;
        END IF;
    ELSE
        -- Convite de congregação geral: apenas ADMIN ou COORDINATOR da congregação
        IF EXISTS (
            SELECT 1 FROM public.congregation_members
            WHERE congregation_id = p_congregation_id
              AND user_id = auth.uid()
              AND role IN ('ADMIN', 'COORDINATOR')
              AND status = 'ACTIVE'
        ) THEN
            v_is_authorized := true;
        END IF;
    END IF;

    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Validar veículo se fornecido
    IF p_assigned_vehicle_id IS NOT NULL THEN
        IF p_event_id IS NULL OR NOT EXISTS (
            SELECT 1 FROM public.vehicles 
            WHERE id = p_assigned_vehicle_id AND event_id = p_event_id
        ) THEN
            RAISE EXCEPTION 'VEHICLE_NOT_FOUND';
        END IF;
    END IF;

    -- Revogar convites pendentes anteriores para o mesmo e-mail no mesmo escopo
    UPDATE public.invitations
    SET status = 'REVOKED'
    WHERE lower(trim(email)) = v_clean_email
      AND congregation_id = p_congregation_id
      AND (
          (p_event_id IS NOT NULL AND event_id = p_event_id)
          OR (p_event_id IS NULL AND event_id IS NULL)
      )
      AND status = 'PENDING';

    -- Calcular data de expiração
    v_expires_at := now() + (GREATEST(1, LEAST(p_expires_in_days, 30)) || ' days')::INTERVAL;

    -- Inserir novo convite
    INSERT INTO public.invitations (
        email,
        congregation_id,
        event_id,
        role,
        assigned_vehicle_id,
        status,
        expires_at,
        invited_by
    ) VALUES (
        v_clean_email,
        p_congregation_id,
        p_event_id,
        p_role,
        p_assigned_vehicle_id,
        'PENDING',
        v_expires_at,
        auth.uid()
    ) RETURNING id INTO v_invitation_id;

    -- Auditoria
    INSERT INTO public.audit_logs (
        congregation_id,
        event_id,
        actor_user_id,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        p_congregation_id,
        p_event_id,
        auth.uid(),
        'CREATE_INVITATION',
        'invitations',
        v_invitation_id,
        jsonb_build_object(
            'email', v_clean_email,
            'role', p_role,
            'expires_at', v_expires_at
        ),
        jsonb_build_object('created_by_user', auth.uid())
    );

    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'email', v_clean_email,
        'role', p_role,
        'expires_at', v_expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. FUNÇÃO RPC: ACEITAR CONVITE (ATÔMICA COM VALIDAÇÃO DE IDENTIDADE E ESCALADA DE PRIVILÉGIOS)
CREATE OR REPLACE FUNCTION public.accept_invitation(
    p_invitation_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_inv public.invitations;
    v_user_email TEXT;
    v_staff_id UUID;
    v_member_role member_role;
BEGIN
    -- Validar autenticação
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    -- Bloquear registro do convite para evitar aceitação concorrente
    SELECT * INTO v_inv
    FROM public.invitations
    WHERE id = p_invitation_id
    FOR UPDATE;

    IF v_inv.id IS NULL THEN
        RAISE EXCEPTION 'INVITATION_NOT_FOUND';
    END IF;

    -- Validar estado
    IF v_inv.status <> 'PENDING' THEN
        RAISE EXCEPTION 'INVITATION_NOT_PENDING';
    END IF;

    -- Validar expiração
    IF v_inv.expires_at < now() THEN
        UPDATE public.invitations SET status = 'EXPIRED' WHERE id = p_invitation_id;
        RAISE EXCEPTION 'INVITATION_EXPIRED';
    END IF;

    -- Obter e normalizar e-mail do usuário autenticado
    SELECT lower(trim(email)) INTO v_user_email
    FROM public.profiles
    WHERE id = auth.uid();

    IF v_user_email IS NULL OR v_user_email = '' THEN
        SELECT lower(trim(email)) INTO v_user_email
        FROM auth.users
        WHERE id = auth.uid();
    END IF;

    -- Confrontar e-mails
    IF lower(trim(v_inv.email)) <> v_user_email THEN
        RAISE EXCEPTION 'EMAIL_MISMATCH';
    END IF;

    -- Determinar papel na congregação com base na role do convite
    IF v_inv.role = 'COORDINATOR' THEN
        v_member_role := 'COORDINATOR';
    ELSIF v_inv.role = 'BUS_CAPTAIN' THEN
        v_member_role := 'CAPTAIN';
    ELSE
        v_member_role := 'MEMBER';
    END IF;

    -- Inserir ou ativar membership na congregação
    INSERT INTO public.congregation_members (
        congregation_id,
        user_id,
        role,
        status
    ) VALUES (
        v_inv.congregation_id,
        auth.uid(),
        v_member_role,
        'ACTIVE'
    )
    ON CONFLICT (congregation_id, user_id) DO UPDATE SET
        role = CASE 
            -- Se já era ADMIN ou COORDINATOR, preserva
            WHEN public.congregation_members.role = 'ADMIN' THEN 'ADMIN'
            WHEN public.congregation_members.role = 'COORDINATOR' THEN 'COORDINATOR'
            ELSE EXCLUDED.role 
        END,
        status = 'ACTIVE',
        updated_at = now();

    -- Se o convite está associado a um evento, configurar equipe e permissões
    IF v_inv.event_id IS NOT NULL THEN
        -- Inserir ou atualizar event_staff
        INSERT INTO public.event_staff (
            event_id,
            user_id,
            role,
            assigned_vehicle_id
        ) VALUES (
            v_inv.event_id,
            auth.uid(),
            v_inv.role,
            v_inv.assigned_vehicle_id
        )
        ON CONFLICT (event_id, user_id) DO UPDATE SET
            role = EXCLUDED.role,
            assigned_vehicle_id = EXCLUDED.assigned_vehicle_id,
            updated_at = now()
        RETURNING id INTO v_staff_id;

        -- Atribuir permissões padrão conforme o papel do convite
        IF v_inv.role = 'COORDINATOR' THEN
            -- Coordenador tem autoridade total
            INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
            SELECT v_staff_id, p.perm, true
            FROM (VALUES 
                ('view_event'), ('manage_event'), ('manage_vehicles'), 
                ('manage_passages'), ('manage_passengers'), ('view_financial_data'), 
                ('manage_payments'), ('view_receipts'), ('export_data'), 
                ('perform_checkin'), ('edit_passenger_list'), ('manage_event_staff'), 
                ('view_audit_log')
            ) AS p(perm)
            ON CONFLICT (event_staff_id, permission) DO UPDATE SET is_granted = true;

        ELSIF v_inv.role = 'COORDINATOR_HELPER' THEN
            -- Ajudante do coordenador (inclui suporte financeiro e administrativo)
            INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
            SELECT v_staff_id, p.perm, true
            FROM (VALUES 
                ('view_event'), ('manage_passages'), ('manage_passengers'), 
                ('view_financial_data'), ('manage_payments'), ('view_receipts'), 
                ('perform_checkin'), ('edit_passenger_list')
            ) AS p(perm)
            ON CONFLICT (event_staff_id, permission) DO UPDATE SET is_granted = true;

        ELSIF v_inv.role = 'BUS_CAPTAIN' THEN
            -- Capitão: operacional apenas. SEM DADOS FINANCEIROS (ADR-003)
            INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
            SELECT v_staff_id, p.perm, true
            FROM (VALUES 
                ('view_event'), ('perform_checkin'), ('edit_passenger_list')
            ) AS p(perm)
            ON CONFLICT (event_staff_id, permission) DO UPDATE SET is_granted = true;

        ELSIF v_inv.role = 'CAPTAIN_HELPER' THEN
            -- Ajudante de Capitão: visualização e check-in. SEM DADOS FINANCEIROS
            INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
            SELECT v_staff_id, p.perm, true
            FROM (VALUES 
                ('view_event'), ('perform_checkin')
            ) AS p(perm)
            ON CONFLICT (event_staff_id, permission) DO UPDATE SET is_granted = true;
        END IF;
    END IF;

    -- Atualizar estado do convite
    UPDATE public.invitations
    SET status = 'ACCEPTED',
        accepted_at = now()
    WHERE id = p_invitation_id;

    -- Auditoria
    INSERT INTO public.audit_logs (
        congregation_id,
        event_id,
        actor_user_id,
        action,
        entity_type,
        entity_id,
        after_data,
        metadata
    ) VALUES (
        v_inv.congregation_id,
        v_inv.event_id,
        auth.uid(),
        'ACCEPT_INVITATION',
        'invitations',
        p_invitation_id,
        jsonb_build_object(
            'role', v_inv.role,
            'accepted_at', now()
        ),
        jsonb_build_object(
            'user_email', v_user_email,
            'event_id', v_inv.event_id
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', p_invitation_id,
        'congregation_id', v_inv.congregation_id,
        'event_id', v_inv.event_id,
        'role', v_inv.role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. FUNÇÃO RPC: REVOGAR CONVITE
CREATE OR REPLACE FUNCTION public.revoke_invitation(
    p_invitation_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_inv public.invitations;
    v_is_authorized BOOLEAN := false;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    SELECT * INTO v_inv
    FROM public.invitations
    WHERE id = p_invitation_id
    FOR UPDATE;

    IF v_inv.id IS NULL THEN
        RAISE EXCEPTION 'INVITATION_NOT_FOUND';
    END IF;

    -- Validar autorização do solicitante
    IF v_inv.event_id IS NOT NULL AND public.is_event_coordinator(v_inv.event_id) THEN
        v_is_authorized := true;
    ELSIF EXISTS (
        SELECT 1 FROM public.congregation_members
        WHERE congregation_id = v_inv.congregation_id
          AND user_id = auth.uid()
          AND role IN ('ADMIN', 'COORDINATOR')
          AND status = 'ACTIVE'
    ) THEN
        v_is_authorized := true;
    END IF;

    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;

    IF v_inv.status <> 'PENDING' THEN
        RAISE EXCEPTION 'INVITATION_NOT_PENDING';
    END IF;

    UPDATE public.invitations
    SET status = 'REVOKED'
    WHERE id = p_invitation_id;

    -- Auditoria
    INSERT INTO public.audit_logs (
        congregation_id,
        event_id,
        actor_user_id,
        action,
        entity_type,
        entity_id,
        after_data
    ) VALUES (
        v_inv.congregation_id,
        v_inv.event_id,
        auth.uid(),
        'REVOKE_INVITATION',
        'invitations',
        p_invitation_id,
        jsonb_build_object('status', 'REVOKED')
    );

    RETURN jsonb_build_object('success', true, 'invitation_id', p_invitation_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. FUNÇÃO RPC: LISTAR CONGREGAÇÕES DO USUÁRIO AUTENTICADO
CREATE OR REPLACE FUNCTION public.get_my_congregations()
RETURNS TABLE (
    congregation_id UUID,
    name TEXT,
    code TEXT,
    city TEXT,
    state TEXT,
    member_role member_role,
    status TEXT
) AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        c.id AS congregation_id,
        c.name,
        c.code,
        c.city,
        c.state,
        cm.role AS member_role,
        cm.status
    FROM public.congregations c
    JOIN public.congregation_members cm ON cm.congregation_id = c.id
    WHERE cm.user_id = auth.uid()
      AND cm.status = 'ACTIVE'
    ORDER BY c.name ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 8. FUNÇÃO RPC: LISTAR CONVITES PENDENTES PARA O E-MAIL DO USUÁRIO
CREATE OR REPLACE FUNCTION public.get_my_pending_invitations()
RETURNS TABLE (
    invitation_id UUID,
    email TEXT,
    congregation_id UUID,
    congregation_name TEXT,
    event_id UUID,
    event_theme TEXT,
    role invitation_role,
    assigned_vehicle_id UUID,
    vehicle_name TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_email TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN;
    END IF;

    SELECT lower(trim(p.email)) INTO v_user_email
    FROM public.profiles p
    WHERE p.id = auth.uid();

    IF v_user_email IS NULL OR v_user_email = '' THEN
        SELECT lower(trim(u.email)) INTO v_user_email
        FROM auth.users u
        WHERE u.id = auth.uid();
    END IF;

    RETURN QUERY
    SELECT 
        i.id AS invitation_id,
        i.email,
        i.congregation_id,
        c.name AS congregation_name,
        i.event_id,
        e.theme AS event_theme,
        i.role,
        i.assigned_vehicle_id,
        v.name AS vehicle_name,
        i.expires_at,
        i.created_at
    FROM public.invitations i
    JOIN public.congregations c ON c.id = i.congregation_id
    LEFT JOIN public.events e ON e.id = i.event_id
    LEFT JOIN public.vehicles v ON v.id = i.assigned_vehicle_id
    WHERE lower(trim(i.email)) = v_user_email
      AND i.status = 'PENDING'
      AND i.expires_at > now()
    ORDER BY i.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
