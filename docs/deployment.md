# Estratégia de Ambientes e Deploy (docs/deployment.md)

Este documento estabelece o fluxo de desenvolvimento, testes e implantação do sistema.

---

## 1. Ambientes Isolados

| Ambiente | Banco de Dados | Domínio/Aplicação | Objetivo |
| :--- | :--- | :--- | :--- |
| **Local (Dev)** | Supabase CLI Docker Local (`127.0.0.1:54322`) | Emulador Android, Chrome Local, Windows | Desenvolvimento diário, testes de migrations e seeds. |
| **Staging** | Projeto Supabase Staging Remoto | Preview Web / TestFlight / Firebase App Distribution | Homologação com coordenadores e capitães voluntários. |
| **Production** | Projeto Supabase Production Remoto | Web Domínio Próprio / Google Play / App Store | Uso oficial durante assembleias e congressos. |

---

## 2. Regra Absoluta de Banco de Dados

- **NUNCA** alterar esquemas diretamente pelo Table Editor do Supabase em produção;
- Toda e qualquer alteração de tabela, enum, índice, RLS ou function deve ser commitada como migração versionada em `supabase/migrations/`;
- **NUNCA** executar `supabase db reset --linked` apontando para o ambiente de produção.
