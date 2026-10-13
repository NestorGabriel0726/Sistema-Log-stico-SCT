# Estratégia e Guia de Testes (docs/testing.md)

Este documento descreve os níveis de testes implementados no sistema e os procedimentos para execução.

---

## 1. Níveis de Testes

### 1.1 Testes Unitários e de Widgets (Flutter / Dart)
Focados em lógica de domínio, estados de autenticação, roteamento e renderização:
- **Cálculo de idade no dia do evento** (`domain_calculations_test.dart`): aniversário antes, no dia e depois do evento;
- **Regra de isenção por idade**: abaixo da idade mínima = isento; igual ou acima = pagante;
- **Cálculo financeiro de passagens**: soma dos dias de viagem x diária;
- **Status financeiro**: transições e valores (`UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERPAID`, `NOT_APPLICABLE`);
- **Formatação monetária e mascaramento de documentos** (CPF mascarado na visualização padrão);
- **Tratamento e tradução amigável de falhas** (`failures_test.dart`): códigos de erro convertidos em mensagens em português;
- **Estados de Autenticação e Autorização** (`auth_state_test.dart`): ciclo completo da hierarquia `AuthState` (Initializing, Unauthenticated, LoadingProfile, PendingAuthorization, HasPendingInvitations, SelectCongregation, Authorized, RecoverableError, SessionExpired);
- **Entidade Congregation e Permissões** (`congregation_test.dart`): parse e display de papéis de congregação (`MemberRole`);
- **Entidade Invitation e Expiração** (`invitation_test.dart`): validação de convites pendentes, expirados e display de papéis;
- **Smoke Tests e Roteamento** (`widget_test.dart`): teste de renderização da tela de login para deslogados, acesso protegido a eventos para autorizados e tela de aviso para usuários aguardando autorização.

### 1.2 Testes de Banco de Dados, RLS e Funções RPC (PostgreSQL)
Implementados em `supabase/tests/database_security_test.sql` cobrindo 14 cenários com rollback automático:
1. Criação automática de perfil no primeiro login;
2. Usuário novo sem congregações nem convites;
3. Criação de convite por coordenador autorizado;
4. Bloqueio de criação de convite por usuário não autorizado (RLS);
5. Leitura de convites pendentes pelo próprio destinatário;
6. Bloqueio de leitura de convites de outros usuários;
7. Aceite atômico de convite válido via RPC `accept_invitation()`;
8. Criação atômica de membership e permissões de staff;
9. Rejeição de aceite de convite por e-mail divergente (`EMAIL_MISMATCH`);
10. Rejeição de aceite de convite expirado (`INVITATION_EXPIRED`);
11. Rejeição de aceite de convite revogado (`INVITATION_NOT_PENDING`);
12. Consulta de congregações ativas via RPC `get_my_congregations()`;
13. Isolamento multi-tenant (RLS impede acesso a dados de outra congregação);
14. Bloqueio estrito de acesso a dados financeiros por papéis não-coordenadores.

---

## 2. Como Executar os Testes

### 2.1 Testes do Flutter

Execute no Windows PowerShell:

```powershell
# Executar todos os testes do Flutter
flutter test

# Executar com relatório de cobertura
flutter test --coverage
```

### 2.2 Testes de Banco de Dados (Supabase / PostgreSQL)

Quando o **Docker Desktop** estiver em execução:

```powershell
# 1. Iniciar containers do Supabase
npx.cmd supabase start

# 2. Aplicar migrações e seeds
npx.cmd supabase db reset

# 3. Executar o script de testes de segurança
# (No Supabase Studio SQL Editor em http://127.0.0.1:54323 ou via psql)
Get-Content supabase\tests\database_security_test.sql | npx.cmd supabase db query
```

> **Nota sobre Docker Desligado**: Caso o serviço do Docker esteja inativo, a suíte de testes Flutter continuará executando normalmente de forma independente, enquanto os testes de integração do banco aguardarão a inicialização do container.
