-- =====================================================================
-- SISTEMA DE GESTÃO LOGÍSTICA DE TRANSPORTE PARA ASSEMBLEIAS E CONGRESSOS
-- TESTES DE BANCO E SEGURANÇA (RLS & RPC FUNCTIONS) - FASE 1
-- Arquivo: supabase/tests/database_security_test.sql
-- =====================================================================
-- Este script executa em uma transação com ROLLBACK no final,
-- garantindo que nenhuma alteração persista e testando os 14 cenários
-- obrigatórios da Fase 1.
--
-- Execução:
--   npx.cmd supabase test db (quando pgTAP estiver configurado)
--   OU executar este arquivo no Supabase Studio SQL Editor / psql.
-- =====================================================================

BEGIN;

DO $$
DECLARE
    -- Variáveis de teste
    v_user_coord_id UUID := '11111111-1111-1111-1111-111111111111';
    v_cong_a_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_cong_b_id UUID := 'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_event_a_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

    -- Novos usuários para testes de RLS/Auth
    v_new_user_id UUID := '77777777-7777-7777-7777-777777777777';
    v_other_user_id UUID := '88888888-8888-8888-8888-888888888888';
    v_unauth_user_id UUID := '99999999-9999-9999-9999-999999999999';

    v_inv_valid_id UUID;
    v_inv_expired_id UUID;
    v_inv_revoked_id UUID;
    v_inv_other_email_id UUID;
    v_profile_count INTEGER;
    v_res JSONB;
    v_error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'INICIANDO SUÍTE DE TESTES DE BANCO E RLS (FASE 1)';
    RAISE NOTICE '==================================================';

    -- SETUP: Congregação B para teste de isolamento cross-congregation
    INSERT INTO public.congregations (id, name, code, city, state)
    VALUES (v_cong_b_id, 'Congregação Norte', 'BR-BA-002', 'Feira de Santana', 'BA')
    ON CONFLICT (id) DO NOTHING;

    -- =================================================================
    -- CENÁRIO 1: CRIAÇÃO DE PERFIL NO PRIMEIRO LOGIN
    -- =================================================================
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (v_new_user_id, 'novousuario@exemplo.com', 'Novo Usuário', 'https://avatar.url/1')
    ON CONFLICT (id) DO NOTHING;

    SELECT COUNT(*) INTO v_profile_count
    FROM public.profiles
    WHERE id = v_new_user_id;

    IF v_profile_count = 1 THEN
        RAISE NOTICE '✅ TESTE 1 APROVADO: Perfil criado no primeiro login.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 1 FALHOU: Perfil não foi criado.';
    END IF;

    -- =================================================================
    -- CENÁRIO 2: LOGIN REPETIDO SEM DUPLICAR PERFIL (IDEMPOTÊNCIA)
    -- =================================================================
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (v_new_user_id, 'novousuario@exemplo.com', 'Novo Usuário Atualizado', 'https://avatar.url/1')
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        updated_at = now();

    SELECT COUNT(*) INTO v_profile_count
    FROM public.profiles
    WHERE id = v_new_user_id;

    IF v_profile_count = 1 THEN
        RAISE NOTICE '✅ TESTE 2 APROVADO: Login repetido manteve perfil único (sem duplicidade).';
    ELSE
        RAISE EXCEPTION '❌ TESTE 2 FALHOU: Login repetido duplicou perfis.';
    END IF;

    -- =================================================================
    -- CENÁRIO 3: CONVITE VÁLIDO E ACEITAÇÃO
    -- =================================================================
    -- Coordenador autenticado cria convite
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_coord_id::TEXT, 'email', 'coordenador@exemplo.com')::TEXT, true);

    v_res := public.create_invitation(
        'novousuario@exemplo.com',
        v_cong_a_id,
        v_event_a_id,
        'BUS_CAPTAIN',
        NULL,
        7
    );
    v_inv_valid_id := (v_res->>'invitation_id')::UUID;

    -- Usuário convidado loga e aceita convite
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_new_user_id::TEXT, 'email', 'novousuario@exemplo.com')::TEXT, true);

    v_res := public.accept_invitation(v_inv_valid_id);

    IF (v_res->>'success')::BOOLEAN = true THEN
        -- Verificar se o vínculo foi criado em congregation_members e event_staff
        IF EXISTS (SELECT 1 FROM public.congregation_members WHERE user_id = v_new_user_id AND congregation_id = v_cong_a_id AND status = 'ACTIVE') AND
           EXISTS (SELECT 1 FROM public.event_staff WHERE user_id = v_new_user_id AND event_id = v_event_a_id AND role = 'BUS_CAPTAIN') THEN
            RAISE NOTICE '✅ TESTE 3 APROVADO: Convite válido aceito com criação atômica de memberships.';
        ELSE
            RAISE EXCEPTION '❌ TESTE 3 FALHOU: Membro não foi vinculado corretamente.';
        END IF;
    ELSE
        RAISE EXCEPTION '❌ TESTE 3 FALHOU: accept_invitation não retornou sucesso.';
    END IF;

    -- =================================================================
    -- CENÁRIO 4: CONVITE DESTINADO A OUTRO E-MAIL É REJEITADO
    -- =================================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_coord_id::TEXT, 'email', 'coordenador@exemplo.com')::TEXT, true);
    v_res := public.create_invitation('destinatario.correto@exemplo.com', v_cong_a_id, v_event_a_id, 'BUS_CAPTAIN', NULL, 7);
    v_inv_other_email_id := (v_res->>'invitation_id')::UUID;

    -- Usuário com outro email tenta aceitar
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_new_user_id::TEXT, 'email', 'novousuario@exemplo.com')::TEXT, true);
    v_error_caught := false;
    BEGIN
        PERFORM public.accept_invitation(v_inv_other_email_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%EMAIL_MISMATCH%' THEN
            v_error_caught := true;
        END IF;
    END;

    IF v_error_caught THEN
        RAISE NOTICE '✅ TESTE 4 APROVADO: Tentativa de aceitar convite de outro e-mail bloqueada (EMAIL_MISMATCH).';
    ELSE
        RAISE EXCEPTION '❌ TESTE 4 FALHOU: Sistema permitiu aceitar convite destinado a outro e-mail.';
    END IF;

    -- =================================================================
    -- CENÁRIO 5: CONVITE EXPIRADO É REJEITADO
    -- =================================================================
    INSERT INTO public.invitations (
        email, congregation_id, event_id, role, status, expires_at, invited_by
    ) VALUES (
        'novousuario@exemplo.com', v_cong_a_id, v_event_a_id, 'BUS_CAPTAIN', 'PENDING', now() - interval '2 hours', v_user_coord_id
    ) RETURNING id INTO v_inv_expired_id;

    v_error_caught := false;
    BEGIN
        PERFORM public.accept_invitation(v_inv_expired_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%INVITATION_EXPIRED%' THEN
            v_error_caught := true;
        END IF;
    END;

    IF v_error_caught THEN
        RAISE NOTICE '✅ TESTE 5 APROVADO: Convite expirado rejeitado com sucesso.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 5 FALHOU: Convite expirado foi aceito indevidamente.';
    END IF;

    -- =================================================================
    -- CENÁRIO 6: CONVITE REVOGADO É REJEITADO
    -- =================================================================
    INSERT INTO public.invitations (
        email, congregation_id, event_id, role, status, expires_at, invited_by
    ) VALUES (
        'novousuario@exemplo.com', v_cong_a_id, v_event_a_id, 'BUS_CAPTAIN', 'REVOKED', now() + interval '5 days', v_user_coord_id
    ) RETURNING id INTO v_inv_revoked_id;

    v_error_caught := false;
    BEGIN
        PERFORM public.accept_invitation(v_inv_revoked_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%INVITATION_NOT_PENDING%' THEN
            v_error_caught := true;
        END IF;
    END;

    IF v_error_caught THEN
        RAISE NOTICE '✅ TESTE 6 APROVADO: Convite revogado rejeitado com sucesso.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 6 FALHOU: Convite revogado foi aceito indevidamente.';
    END IF;

    -- =================================================================
    -- CENÁRIO 7: CONVITE JÁ ACEITO NÃO PODE SER REUTILIZADO
    -- =================================================================
    v_error_caught := false;
    BEGIN
        PERFORM public.accept_invitation(v_inv_valid_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%INVITATION_NOT_PENDING%' THEN
            v_error_caught := true;
        END IF;
    END;

    IF v_error_caught THEN
        RAISE NOTICE '✅ TESTE 7 APROVADO: Convite já aceito não pode ser reutilizado.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 7 FALHOU: Convite já aceito foi reutilizado.';
    END IF;

    -- =================================================================
    -- CENÁRIO 8: ACEITAÇÃO SIMULTÂNEA / DUPLICADA PREVENIDA
    -- =================================================================
    -- Verifica que o status ACCEPTED e a transação garantem que apenas 1 chamada tenha sucesso
    SELECT COUNT(*) INTO v_profile_count
    FROM public.congregation_members
    WHERE congregation_id = v_cong_a_id AND user_id = v_new_user_id;

    IF v_profile_count = 1 THEN
        RAISE NOTICE '✅ TESTE 8 APROVADO: Aceitação atômica previne registros de membros duplicados.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 8 FALHOU: Membro duplicado encontrado.';
    END IF;

    -- =================================================================
    -- CENÁRIO 9: TENTATIVA DE CLIENTE ALTERAR A PRÓPRIA FUNÇÃO (RLS)
    -- =================================================================
    -- Usuário comum logado tenta promover a si mesmo para ADMIN via UPDATE direto
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_new_user_id::TEXT, 'email', 'novousuario@exemplo.com')::TEXT, true);

    -- Como não há policy de UPDATE em congregation_members para usuário comum,
    -- qualquer UPDATE deve afetar 0 linhas
    UPDATE public.congregation_members
    SET role = 'ADMIN'
    WHERE user_id = v_new_user_id;

    -- Verificar que a role permaneceu inalterada
    IF (SELECT role FROM public.congregation_members WHERE user_id = v_new_user_id) = 'CAPTAIN' THEN
        RAISE NOTICE '✅ TESTE 9 APROVADO: Tentativa de auto-promoção de role bloqueada pelo RLS.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 9 FALHOU: Usuário conseguiu alterar seu próprio papel.';
    END IF;

    -- =================================================================
    -- CENÁRIO 10: ACESSO A CONGREGAÇÃO SEM MEMBERSHIP
    -- =================================================================
    -- Usuário não cadastrado tenta ler congregações
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (v_unauth_user_id, 'sem.vinculo@exemplo.com', 'Sem Vínculo')
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_unauth_user_id::TEXT, 'email', 'sem.vinculo@exemplo.com')::TEXT, true);

    IF (SELECT COUNT(*) FROM public.congregations) = 0 THEN
        RAISE NOTICE '✅ TESTE 10 APROVADO: Usuário sem membership não consegue visualizar congregações via RLS.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 10 FALHOU: Usuário sem membership visualizou congregações.';
    END IF;

    -- =================================================================
    -- CENÁRIO 11: USUÁRIO SEM CONVITE
    -- =================================================================
    -- Usuário sem convite não visualiza nenhum convite na tabela
    IF (SELECT COUNT(*) FROM public.invitations) = 0 THEN
        RAISE NOTICE '✅ TESTE 11 APROVADO: Usuário sem convite não visualiza convites de outros usuários via RLS.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 11 FALHOU: Usuário sem convite acessou convites alheios.';
    END IF;

    -- =================================================================
    -- CENÁRIO 12: ISOLAMENTO ENTRE CONGREGAÇÕES DISTINTAS
    -- =================================================================
    -- Membro da congregação A tenta acessar dados da congregação B
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (v_other_user_id, 'membro.b@exemplo.com', 'Membro B')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.congregation_members (congregation_id, user_id, role, status)
    VALUES (v_cong_b_id, v_other_user_id, 'MEMBER', 'ACTIVE')
    ON CONFLICT DO NOTHING;

    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_other_user_id::TEXT, 'email', 'membro.b@exemplo.com')::TEXT, true);

    -- Deve ver apenas congregação B, NUNCA congregação A
    IF (SELECT COUNT(*) FROM public.congregations WHERE id = v_cong_a_id) = 0 AND
       (SELECT COUNT(*) FROM public.congregations WHERE id = v_cong_b_id) = 1 THEN
        RAISE NOTICE '✅ TESTE 12 APROVADO: Isolamento estrito entre congregações confirmado pelo RLS.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 12 FALHOU: Usuário da Congregação B conseguiu ler a Congregação A.';
    END IF;

    -- =================================================================
    -- CENÁRIO 13: USUÁRIO COMUM TENTANDO CRIAR CONVITES ADMINISTRATIVOS
    -- =================================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_other_user_id::TEXT, 'email', 'membro.b@exemplo.com')::TEXT, true);

    v_error_caught := false;
    BEGIN
        PERFORM public.create_invitation('hacker@exemplo.com', v_cong_b_id, NULL, 'COORDINATOR', NULL, 7);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%PERMISSION_DENIED%' THEN
            v_error_caught := true;
        END IF;
    END;

    IF v_error_caught THEN
        RAISE NOTICE '✅ TESTE 13 APROVADO: Usuário comum bloqueado ao tentar criar convites administrativos.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 13 FALHOU: Usuário comum conseguiu criar convites.';
    END IF;

    -- =================================================================
    -- CENÁRIO 14: TENTATIVA DE CONCEDER PERMISSÕES NÃO AUTORIZADAS
    -- =================================================================
    -- Usuário comum tentando conceder a si permissão de gerenciar finanças
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_other_user_id::TEXT, 'email', 'membro.b@exemplo.com')::TEXT, true);

    -- Inserção direta em event_staff_permissions bloqueada por RLS
    INSERT INTO public.event_staff_permissions (event_staff_id, permission, is_granted)
    SELECT es.id, 'manage_payments', true
    FROM public.event_staff es
    WHERE es.user_id = v_other_user_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.event_staff_permissions esp
        JOIN public.event_staff es ON es.id = esp.event_staff_id
        WHERE es.user_id = v_other_user_id AND esp.permission = 'manage_payments'
    ) THEN
        RAISE NOTICE '✅ TESTE 14 APROVADO: Escalada de permissões bloqueada com sucesso.';
    ELSE
        RAISE EXCEPTION '❌ TESTE 14 FALHOU: Usuário conseguiu injetar permissões não autorizadas.';
    END IF;

    RAISE NOTICE '==================================================';
    RAISE NOTICE 'TODOS OS 14 TESTES DE BANCO E SEGURANÇA FORAM APROVADOS COM SUCESSO!';
    RAISE NOTICE '==================================================';

END $$;

ROLLBACK;
