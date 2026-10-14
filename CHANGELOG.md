# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

## [2.1.0] - 2026-10-14 - MVP operacional local (sem Supabase)

### Adicionado
- CRUD de eventos, veículos e passagens/passageiros com dias individuais.
- Filtros de passagens (financeiro / dados / OK) e de passageiros.
- Alocação em lista numerada, desistência com substituto e realocação entre veículos.
- Dashboard com gráfico de passageiros por dia, prazos e lotação.
- Quatro papéis e toggles de check-in.
- Persistência local via SharedPreferences.
- Formulários de evento e passagem, autocomplete de cadastro e regra de isenção por idade.

## [2.0.0] - 2026-10-14 - Reformulação: app local, UI nova, código enxuto

### Adicionado
- Backend em memória (`LocalAppStore`) com seed de demonstração.
- Nova identidade visual (Plus Jakarta Sans, layout simplificado).
- Fluxo: welcome → eventos → detalhe com abas operacionais.

### Removido (do app Flutter)
- Dependências Supabase/Google Sign-In e camada `features/*` anterior.
- Realtime, convites multi-etapa e telas legadas.

### Mantido
- Pasta `supabase/` intacta para integração futura.
- Regras de domínio em `domain_calculations.dart`.

## [0.2.0] - 2026-10-14 - Fase 2 (início): Integração operacional Flutter ↔ Supabase

### Adicionado
- Feature **events** completa (domain/data/providers) com lista e detalhe integrados ao banco.
- Módulos **people**, **vehicles**, **passengers**, **allocations**, **checkins**, **passages**, **notifications** com data sources e providers Riverpod.
- Consumo das views `vehicle_daily_capacity_summary` e `passage_financial_summary` no dashboard (respeitando permissões).
- Realtime: `RealtimeSubscriptionManager`, `realtimeConnectionProvider` e `RealtimeConnectionBadge`.
- Script `scripts/validate-dev.ps1`, workflow CI `.github/workflows/flutter.yml`, checklist `docs/staging-checklist.md`.
- Edge Function stub `supabase/functions/push-notification`.
- Teste unitário `transport_event_model_test.dart`.

### Alterado
- Documentação alinhada ao uso de `--dart-define` em [SETUP.md](SETUP.md) e [.env.example](.env.example).
- [README.md](README.md): estrutura real de `lib/features/` e status da Fase 2.
- `appRouter` marcado como `@Deprecated` — usar `routerProvider`.

## [0.1.1] - 2026-10-13 - Fase 1: Autenticação, Convites e Rotas Protegidas

### Adicionado
- Migration `20261013160000_phase1_auth_invitations.sql` (trigger de perfil, RPCs de convites, memberships).
- Fluxo Flutter: Google OAuth, `AuthState`, GoRouter reativo, telas de convites e congregação.
- Testes Flutter de auth/convites e script SQL `supabase/tests/database_security_test.sql`.

## [0.1.0] - 2026-10-09 - Fase 0: Arquitetura Base e Infraestrutura como Código

### Adicionado
- **Infraestrutura Supabase como Código**:
  - Configuração do projeto via `supabase/config.toml` (PostgreSQL 17).
  - Migration inicial `20261009160000_initial_schema.sql` contendo:
    - Tipos Enumerados (`event_type`, `event_status`, `passenger_category`, `allocation_status`, etc.).
    - Tabelas-base: `profiles`, `congregations`, `congregation_members`, `people`, `events`, `event_days`, `vehicles`, `event_staff`, `event_staff_permissions`, `invitations`, `event_passengers`, `passenger_days`, `passages`, `passage_passengers`, `payments`, `payment_receipts`, `passenger_allocations`, `check_ins`, `notifications`, `notification_devices`, `audit_logs`.
    - Índices estratégicos de performance e constraints relacionais.
    - Funções de autorização e cálculo (`calculate_age_on_date`, `normalize_text`, `is_event_coordinator`, `has_event_permission`, `is_assigned_captain`).
    - Views analíticas e operacionais (`passage_financial_summary`, `vehicle_daily_capacity_summary`, `passenger_operational_list`).
    - Funções RPC transacionais para concorrência atômica (`allocate_passenger`, `relocate_passenger`, `mark_passenger_desisted`, `perform_checkin`, `record_payment`).
    - Políticas de Row Level Security (RLS) protegendo dados sensíveis e isolando congregações.
  - Script de dados de teste `supabase/seed.sql` cobrindo congregação, evento de 3 dias, múltiplos papéis, veículos, isenção por idade, pagamento parcial e realocação.
- **Frontend Flutter**:
  - Inicialização do projeto multiplataforma (Web, Android, iOS, Windows, macOS).
  - Estrutura modular *feature-first* configurada em `lib/`.
  - Design system adaptativo com tokens em `lib/core/theme/`.
  - Documentação completa em `README.md`, `SETUP.md`, `ARCHITECTURE.md` e pasta `docs/`.
