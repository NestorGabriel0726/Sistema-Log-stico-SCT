# Matriz de Permissões e Segurança (docs/permissions.md)

Este documento especifica o modelo de controle de acesso baseado em papéis (*Role-Based Access Control* - RBAC) e permissões explícitas por evento.

---

## 1. Papéis por Evento (`invitation_role`)

Os papéis são vinculados ao **evento**, não globalmente ao usuário. Um irmão pode ser Capitão no Congresso de 2026 e não exercer essa função na Assembleia seguinte.

- **COORDINATOR (Coordenador do Evento)**: Controle máximo sobre todas as áreas do evento (financeiro, veículos, equipe, passageiros, configurações e auditoria).
- **COORDINATOR_HELPER (Ajudante do Coordenador)**: Apoio administrativo conforme permissões explícitas concedidas.
- **BUS_CAPTAIN (Capitão de Veículo)**: Foco operacional sobre o veículo sob sua responsabilidade e consulta aos demais veículos em modo somente-leitura.
- **CAPTAIN_HELPER (Ajudante do Capitão)**: Apoio operacional direto ao capitão no veículo designado.

---

## 2. Permissões Granulares Explícitas

Não confiamos apenas no rótulo do papel. A tabela `event_staff_permissions` define permissões atômicas:

| Código da Permissão | Descrição | Padrão Coordenador | Padrão Capitão |
| :--- | :--- | :---: | :---: |
| `view_event` | Visualizar informações gerais do evento | Sim | Sim |
| `manage_event` | Editar datas, tema, valor da diária, idade de isenção | Sim | Não |
| `manage_vehicles` | Cadastrar e alterar capacidade de ônibus/carros | Sim | Não |
| `manage_passages` | Criar e editar grupos de passagem | Sim | Não |
| `manage_passengers` | Cadastrar passageiros e responsáveis | Sim | Não |
| `view_financial_data` | Ver total esperado, total pago e saldos | Sim | **NÃO (Bloqueado por RLS)** |
| `manage_payments` | Registrar pagamentos em dinheiro ou PIX | Sim | **NÃO (Bloqueado por RLS)** |
| `view_receipts` | Visualizar fotos de recibos no Storage | Sim | **NÃO (Bloqueado por RLS)** |
| `export_data` | Exportar relatórios em PDF e CSV | Sim | Sim (sem dados financeiros) |
| `perform_checkin` | Realizar check-in diário (ida/volta) | Sim | Sim |
| `edit_passenger_list` | Transferir, substituir ou marcar desistência | Sim | Opcional (ativado pelo Coordenador) |
| `manage_event_staff` | Convidar equipe e atribuir permissões | Sim | Não |
| `view_audit_log` | Visualizar histórico completo de auditoria | Sim | Não |

---

## 3. Coordenador Atuando Como Capitão

O Coordenador pode assumir o papel operacional de um veículo sem criar uma conta secundária. A interface Flutter disponibiliza uma alternância de visão ("Modo Operacional do Veículo"), mantendo todas as credenciais administrativas preservadas.
