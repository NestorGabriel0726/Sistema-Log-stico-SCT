# Documento de Arquitetura de Software (ARCHITECTURE.md)

## 1. Visão Geral e Princípios Fundamentais

O sistema foi arquitetado como um **quadro branco digital estruturado, colaborativo e em tempo real** para a gestão logística de transporte de congregações em assembleias e congressos.

### Hierarquia de Prioridades (Regra de Ouro)
```text
INTEGRIDADE DOS DADOS > SEGURANÇA > RASTREABILIDADE > SINCRONIZAÇÃO > UX > COMPLEXIDADE
```

### Princípio da Fonte Única da Verdade
- O banco de dados **PostgreSQL (via Supabase)** é a autoridade máxima e única fonte da verdade.
- O cliente Flutter **nunca calcula capacidade ou status financeiro como autoridade definitiva**; ele consome views e chama funções atômicas via RPC.

---

## 2. Camadas da Aplicação Flutter

A aplicação segue uma estrutura modular dividida por funcionalidades (*feature-first*):

```text
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   - Widgets (Mobile, Tablet, Desktop adaptativos)      │
│   - Design System (AppTheme, AppColors, AppSpacing)    │
│   - Providers (Riverpod Feature State Notifiers)       │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                      DOMAIN LAYER                      │
│   - Entities (Modelos de domínio imutáveis)            │
│   - Value Objects & Validadores                        │
│   - Use Cases (Regras de negócio de aplicação)         │
│   - Repository Interfaces (Contratos abstratos)        │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                       DATA LAYER                       │
│   - DTOs & Mappers (Serialização/Desserialização)      │
│   - Repository Implementations                         │
│   - Remote Data Sources (Supabase Client, RPCs)        │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    SUPABASE & POSTGRES                 │
│   - Row Level Security (RLS)                           │
│   - PostgreSQL Database Functions (RPCs Transacionais) │
│   - Analytical Views                                   │
│   - Triggers de Normalização e Auditoria               │
│   - Supabase Realtime (WebSockets)                     │
│   - Supabase Storage (Private Buckets com RLS)         │
└────────────────────────────────────────────────────────┘
```

---

## 3. Gestão de Concorrência e Operações Transacionais

Para prevenir *race conditions* (por exemplo, dois operadores tentando alocar o 30º assento de um veículo simultaneamente), nenhuma lógica de escrita crítica é executada através de `SELECT` seguido de `INSERT` no Flutter.

Toda alteração de capacidade, realocação, desistência ou check-in é executada via **PostgreSQL Database Functions** com bloqueio transacional (`FOR UPDATE`), garantindo que:
1. O bloqueio atômico de linha impede concorrência indevida;
2. As constraints e capacidades locais são verificadas em tempo de commit;
3. O registro de auditoria (`audit_logs`) e a alteração da alocação ocorrem na mesma transação. Se uma falhar, toda a operação sofre *rollback*.

---

## 4. Matriz de Segurança e Privacidade em Profundidade

O sistema garante que dados confidenciais nunca cheguem aos dispositivos não autorizados:

| Dado / Recurso | Coordenador | Ajudante Coordenador | Capitão de Ônibus | Ajudante de Capitão |
| :--- | :---: | :---: | :---: | :---: |
| Lista de Passageiros do seu veículo | Visualiza e Edita* | Visualiza e Edita* | Visualiza e Edita* | Visualiza e Edita* |
| Listas de Outros Veículos | Completo | Completo | Somente Leitura | Somente Leitura |
| Check-in Diário (Ida/Volta) | Sim | Sim (se concedido) | Sim (se concedido) | Sim (se concedido) |
| Valores Financeiros / Saldo | Sim | Sim (se concedido) | **BLOQUEADO (RLS)** | **BLOQUEADO (RLS)** |
| Formas de Pagamento / PIX | Sim | Sim (se concedido) | **BLOQUEADO (RLS)** | **BLOQUEADO (RLS)** |
| Fotos de Comprovantes (Storage) | Sim | Sim (se concedido) | **BLOQUEADO (RLS)** | **BLOQUEADO (RLS)** |

*\* A edição de lista por capitães depende da flag explícita `edit_passenger_list = true` configurada pelo coordenador.*

---

## 5. Estratégia de Tempo Real (Supabase Realtime)

O aplicativo estabelece canais de subscrição seletivos por tela:
- Na tela de um veículo específico, assina apenas as alterações de `passenger_allocations` e `check_ins` do dia e veículo abertos;
- O canal de `notifications` escuta apenas as notificações direcionadas ao `auth.uid()` logado.
