# Arquitetura e Sincronização em Tempo Real (docs/realtime.md)

Este documento descreve como o sistema sincroniza alterações operacionais instantaneamente entre múltiplos dispositivos sem requerer recarregamento da página (F5).

---

## 1. Princípio de Funcionamento

O sistema utiliza o **Supabase Realtime (WebSockets)** integrado aos eventos de replicação lógica do PostgreSQL:

```text
Ação do Usuário A (ex: Coordenador realoca João do Ônibus 2 para o Ônibus 1)
   │
   ▼
Chamada RPC: relocate_passenger()
   │
   ▼
Transação PostgreSQL (atualiza passenger_allocations, insere audit_logs, commit)
   │
   ▼
Supabase Realtime Engine (Postgres Changes)
   │
   ├──▶ Dispositivo B (Capitão Ônibus 2): João aparece com badge "Relocado para Ônibus 1" (Lotação: 30/30 -> 29/30)
   │
   └──▶ Dispositivo C (Capitão Ônibus 1): João entra na lista (Lotação: 28/30 -> 29/30)
```

---

## 2. Inscrições Seletivas por Tela (Otimização de Recursos)

Para garantir excelente desempenho e economia de banda em conexões móveis:
- **Tela de Lista do Veículo**: Escuta apenas `passenger_allocations` com filtro no `vehicle_id` e dia selecionado;
- **Tela de Check-in**: Escuta `check_ins` do dia e veículo correspondente;
- **Centro de Notificações**: Escuta `notifications` filtrado por `recipient_user_id = eq.<auth.uid>`.

---

## 3. Tratamento de Desconexão e Reconexão

Quando um dispositivo perde a conectividade:
1. O aplicativo exibe indicador visual contextual (`● Reconectando...`);
2. Bloqueia temporariamente submissões que dependam de confirmação atômica;
3. Ao restabelecer a conexão, o canal reativa a subscrição e executa uma query de reconciliação de estado, garantindo que nenhum evento perdido permaneça defasado.
