# Sistema de Notificações In-App e Push (docs/notifications.md)

Este documento descreve a arquitetura do centro de notificações persistente e o fluxo de envio de notificações push.

---

## 1. Duplo Mecanismo de Comunicação

O sistema opera com duas camadas complementares:
1. **Sincronização em Tempo Real (Supabase Realtime)**: Atualiza instantaneamente os quadros, listas e contadores de lotação na tela ativa.
2. **Notificação Persistente (`notifications`)**: Registra alertas no banco para leitura assíncrona, exibição de badge de contagem de não-lidas e histórico no sino de notificações.

---

## 2. Fluxo de Notificação Push Server-Side

Nenhuma notificação push é disparada diretamente a partir do cliente Flutter para garantir confiabilidade:

```text
Ação no Cliente Flutter
   │
   ▼
Database Function PostgreSQL (ex: relocate_passenger)
   │
   ▼
Insert na tabela 'notifications'
   │
   ▼
Supabase Database Webhook
   │
   ▼
Supabase Edge Function (TypeScript/Deno)
   │
   ▼
Firebase Cloud Messaging (FCM) / APNs (Apple)
   │
   ▼
Dispositivo Móvel do Usuário
```

---

## 3. Segurança e Privacidade das Mensagens

Notificações **nunca** incluem documentos pessoais (CPF, RG), dados financeiros (valores pagos, saldos) ou comprovantes:
- **Correto**: *"João da Silva foi realocado para o Ônibus 01."*
- **Incorreto**: *"João (CPF 123.456...) pagou R$ 150 e foi transferido."*
