# Registro de Decisões de Arquitetura (docs/decision-log.md)

Este documento registra formalmente as decisões arquiteturais (ADRs - *Architecture Decision Records*) adotadas no projeto.

---

## ADR-001: Supabase/PostgreSQL como Backend Oficial e Única Fonte da Verdade

- **Status**: Aceito.
- **Contexto**: A aplicação requer transações atômicas, RLS avançado, persistência relacional forte e suporte a realtime.
- **Decisão**: Utilizar exclusivamente PostgreSQL gerenciado pelo Supabase. É proibido o uso simultâneo de outros bancos primários como Firebase Firestore ou MongoDB.
- **Consequências**: Garantia de integridade ACID, simplificação da arquitetura e eliminação de conflitos de concorrência entre múltiplas fontes de verdade.

---

## ADR-002: Operações Críticas de Concorrência via PostgreSQL Functions (RPC)

- **Status**: Aceito.
- **Contexto**: Dois operadores podem tentar alocar passageiros simultaneamente no último assento de um veículo (ex: 29/30). Fazer `SELECT` no Flutter e `INSERT` em seguida gera *race conditions*.
- **Decisão**: Implementar `allocate_passenger`, `relocate_passenger`, `mark_passenger_desisted`, `perform_checkin` e `record_payment` exclusivamente como funções no banco com lock `FOR UPDATE`.
- **Consequências**: Operações atômicas, impossibilidade de ultrapassar a capacidade local do veículo (ex: 31/30) e auditoria gerada atomicamente na mesma transação.

---

## ADR-003: Proteção Estrita de Dados Financeiros via RLS

- **Status**: Aceito.
- **Contexto**: Capitães e ajudantes de capitão operam os veículos, mas não devem ter acesso a valores pagos, saldos, pagamentos PIX ou fotos de comprovantes.
- **Decisão**: Restringir as tabelas `passages`, `payments` e `payment_receipts` estritamente ao Coordenador e ajudantes autorizados através de políticas RLS no PostgreSQL.
- **Consequências**: Segurança em profundidade; mesmo que um usuário inspecione a rede ou tente requisições manuais via client API, o banco recusa a leitura de dados financeiros.

---

## ADR-004: Snapshots de Dados Cadastrais no Evento

- **Status**: Aceito.
- **Contexto**: Mudanças futuras no cadastro mestre de pessoas (tabela `people`) não podem alterar silenciosamente listas oficiais de eventos passados.
- **Decisão**: A tabela `event_passengers` armazena snapshots (`full_name_snapshot`, `document_type_snapshot`, `document_number_snapshot`, `birth_date_snapshot`, `responsible_name_snapshot`).
- **Consequências**: Preservação estrita do histórico legal e fiscal do evento.

---

## ADR-005: Lista Vertical Numerada em vez de Mapa Visual de Assentos

- **Status**: Aceito.
- **Contexto**: A dinâmica de transporte de congregação exige flexibilidade operacional para trocas de última hora, não um sistema rígido de reserva de poltronas estilo companhia aérea.
- **Decisão**: O controle é realizado por listas verticais numeradas e capacidade total. O número representa apenas a posição na lista.
- **Consequências**: Alta velocidade de remanejamento, interface limpa para celular e adequação à realidade dos eventos.
