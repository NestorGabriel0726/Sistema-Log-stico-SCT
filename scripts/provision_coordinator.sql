-- =====================================================================
-- SCRIPT DE PROVISIONAMENTO INICIAL SEGURO (scripts/provision_coordinator.sql)
-- =====================================================================
-- Este script deve ser executado exclusivamente em ambiente administrativo
-- (ex: Supabase Studio SQL Editor local/remoto ou psql administrativo).
--
-- NUNCA execute em clientes Flutter e NUNCA exponha credenciais privilegiadas.
-- =====================================================================

DO $$
DECLARE
    -- 1. DEFINA OS DADOS AUTORIZADOS DO COORDENADOR E DA CONGREGAÇÃO
    v_coordinator_email TEXT := 'coordenador@exemplo.com'; -- ALTERE PARA O E-MAIL GOOGLE REAL DO COORDENADOR
    v_congregation_name TEXT := 'Congregação Central';
    v_congregation_city TEXT := 'Salvador';
    v_congregation_state TEXT := 'BA';
    v_congregation_code TEXT := 'BR-BA-001';

    -- Variáveis internas de controle
    v_congregation_id UUID;
    v_invitation_id UUID;
    v_existing_user_id UUID;
BEGIN
    v_coordinator_email := lower(trim(v_coordinator_email));

    IF v_coordinator_email = '' OR position('@' in v_coordinator_email) = 0 THEN
        RAISE EXCEPTION 'E-mail do coordenador inválido.';
    END IF;

    -- 2. OBTER OU CRIAR A CONGREGAÇÃO INICIAL
    SELECT id INTO v_congregation_id
    FROM public.congregations
    WHERE name = v_congregation_name
    LIMIT 1;

    IF v_congregation_id IS NULL THEN
        INSERT INTO public.congregations (name, code, city, state)
        VALUES (v_congregation_name, v_congregation_code, v_congregation_city, v_congregation_state)
        RETURNING id INTO v_congregation_id;
        RAISE NOTICE 'Congregação criada com ID: %', v_congregation_id;
    ELSE
        RAISE NOTICE 'Congregação existente identificada com ID: %', v_congregation_id;
    END IF;

    -- 3. VERIFICAR SE O USUÁRIO JÁ EXISTE NO AUTH OU SE PRECISA DE CONVITE
    SELECT id INTO v_existing_user_id
    FROM auth.users
    WHERE lower(trim(email)) = v_coordinator_email;

    IF v_existing_user_id IS NOT NULL THEN
        -- Se o usuário já logou anteriormente, vincula diretamente como COORDINATOR
        INSERT INTO public.congregation_members (congregation_id, user_id, role, status)
        VALUES (v_congregation_id, v_existing_user_id, 'COORDINATOR', 'ACTIVE')
        ON CONFLICT (congregation_id, user_id) DO UPDATE SET
            role = 'COORDINATOR',
            status = 'ACTIVE',
            updated_at = now();

        RAISE NOTICE 'Usuário já cadastrado (%) vinculado diretamente como COORDINATOR da congregação %.', v_coordinator_email, v_congregation_name;
    ELSE
        -- 4. SE O USUÁRIO AINDA NÃO LOGOU, REGISTRAR CONVITE PENDENTE
        -- Revoga convites pendentes anteriores para evitar duplicidade
        UPDATE public.invitations
        SET status = 'REVOKED'
        WHERE lower(trim(email)) = v_coordinator_email
          AND congregation_id = v_congregation_id
          AND event_id IS NULL
          AND status = 'PENDING';

        INSERT INTO public.invitations (
            email,
            congregation_id,
            event_id,
            role,
            status,
            expires_at
        ) VALUES (
            v_coordinator_email,
            v_congregation_id,
            NULL, -- Convite de congregação geral
            'COORDINATOR',
            'PENDING',
            now() + interval '30 days'
        ) RETURNING id INTO v_invitation_id;

        RAISE NOTICE 'Convite administrativo criado com sucesso! ID: %, E-mail: %, Congregação: %', v_invitation_id, v_coordinator_email, v_congregation_name;
        RAISE NOTICE 'Quando o usuário entrar com a conta Google %, o sistema detectará o convite e permitirá a aceitação.', v_coordinator_email;
    END IF;

    -- Registrar auditoria do provisionamento
    INSERT INTO public.audit_logs (
        congregation_id,
        action,
        entity_type,
        metadata
    ) VALUES (
        v_congregation_id,
        'PROVISION_COORDINATOR',
        'congregations',
        jsonb_build_object(
            'coordinator_email', v_coordinator_email,
            'congregation_name', v_congregation_name
        )
    );
END $$;
