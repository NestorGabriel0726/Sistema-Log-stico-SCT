# Sistema de Gestão Logística de Transporte para Assembleias e Congressos

Aplicação multiplataforma profissional desenvolvida em **Flutter + Dart** com backend gerenciado via **Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)**.

O sistema funciona como um **quadro branco digital colaborativo e estruturado** para controle de transporte em Assembleias de Circuito e Congressos Regionais, priorizando:
- **Flexibilidade operacional** (alterações e transferências de última hora);
- **Sincronização em tempo real** entre múltiplos dispositivos sem necessidade de recarregar a página;
- **Integridade dos dados e defesa em profundidade** através de PostgreSQL Database Functions e Row Level Security (RLS);
- **Rastreabilidade e auditoria obrigatória** de todas as ações operacionais e financeiras;
- **Privacidade por perfil**: Capitães de ônibus possuem acesso operacional completo à lista e check-in, mas **bloqueio absoluto a valores financeiros, pagamentos e fotos de recibos**.

---

## 🚀 Arquitetura Geral

```text
Flutter (Web, Android, iOS, Windows, macOS)
  │
  ▼
State Management (Riverpod) & Navigation (GoRouter)
  │
  ▼
Domain Use Cases & Entities
  │
  ▼
Data Repositories & Data Sources
  │
  ▼
Supabase Client (Auth, Realtime, Storage)
  │
  ▼
PostgreSQL (RLS, Constraints, Triggers, Views, RPC Functions)
```

---

## 📋 Stack Tecnológica Oficial

- **Frontend**: Flutter 3.44+ / Dart 3.12+ (Web, Android, iOS, Windows, macOS)
- **Gerenciamento de Estado**: Flutter Riverpod
- **Navegação**: GoRouter
- **Design System**: Material 3 adaptativo (Mobile, Tablet, Desktop)
- **Backend**: Supabase (PostgreSQL 17, Supabase Auth com Google OAuth, Supabase Realtime, Supabase Storage)
- **Operações Críticas**: PostgreSQL Functions / RPCs transacionais atômicas

---

## 📂 Estrutura do Repositório

```text
├── lib/
│   ├── app/                    # Inicialização do app e GoRouter
│   ├── core/                   # Design system, temas, erros, rede, i18n
│   │   ├── error/
│   │   ├── localization/
│   │   ├── network/
│   │   ├── theme/
│   │   └── utils/
│   └── features/               # Arquitetura modular por funcionalidade
│       ├── auth/
│       ├── congregations/
│       ├── events/
│       ├── people/
│       ├── passages/
│       ├── payments/
│       ├── vehicles/
│       ├── allocations/
│       ├── checkins/
│       ├── notifications/
│       ├── audit/
│       └── dashboard/
├── supabase/
│   ├── config.toml             # Configuração do Supabase CLI
│   ├── migrations/             # Migrações versionadas do banco (IaC)
│   ├── functions/              # Edge Functions
│   └── seed.sql                # Dados simulados para desenvolvimento
├── docs/                       # Documentação técnica aprofundada
│   ├── database.md             # Esquema ER e relacionamentos
│   ├── permissions.md          # Matriz de autorização e RLS
│   ├── realtime.md             # Estratégia de sincronização em tempo real
│   ├── notifications.md        # Arquitetura de notificações in-app e push
│   ├── deployment.md           # Guia de ambientes e deploy
│   ├── decision-log.md         # Registro de decisões de arquitetura (ADRs)
│   └── testing.md              # Estratégia e execução de testes
├── SETUP.md                    # Passo a passo detalhado para desenvolvedores
├── ARCHITECTURE.md             # Visão profunda da arquitetura
└── CHANGELOG.md                # Histórico de versões
```

---

## ⚡ Como Começar

Consulte o guia completo em [SETUP.md](file:///c:/Users/232.953513/Desktop/Projeto%20Nestor/SETUP.md).

```powershell
# 1. Instalar dependências Flutter
flutter pub get

# 2. Executar análise estática
flutter analyze

# 3. Executar testes
flutter test
```
