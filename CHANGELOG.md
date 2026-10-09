# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

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
