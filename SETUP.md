# Manual de Configuração do Ambiente de Desenvolvimento (SETUP.md)

Este documento foi elaborado para fornecer instruções passo a passo para configuração e execução do projeto no Windows (via PowerShell) e demais sistemas operacionais.

---

## 1. Pré-requisitos

1. **Flutter SDK**: Versão estável (3.22 ou superior, recomendado 3.44+).
2. **Docker Desktop**: Necessário para execução do Supabase Local.
3. **Node.js**: Versão LTS (v20+ ou v24+).
4. **Supabase CLI**: Executável via `npx supabase` ou instalado globalmente.
5. **Git**.

---

## 2. Verificação Inicial das Ferramentas

Abra o terminal **PowerShell** no diretório do projeto e execute:

```powershell
flutter doctor
node -v
docker --version
npx supabase --version
```

---

## 3. Configuração do Supabase Local

O banco de dados PostgreSQL é gerenciado 100% como código através das migrações em `supabase/migrations`.

### 3.1 Iniciar Containers do Supabase Local

Certifique-se de que o **Docker Desktop** esteja em execução e execute:

```powershell
npx supabase start
```

Ao concluir a inicialização, o terminal exibirá:
- **API URL**: Ex: `http://127.0.0.1:54321`
- **GraphQL URL**: Ex: `http://127.0.0.1:54321/graphql/v1`
- **DB URL**: Ex: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- **Studio URL**: `http://127.0.0.1:54323` (Interface visual de gerenciamento local)
- **anon key**: Chave pública de cliente (Safe for Flutter)
- **service_role key**: Chave administrativa privada (**NUNCA colocar no Flutter**)

### 3.2 Resetar Banco e Aplicar Migrations e Seeds

Para resetar a base local, aplicar todas as migrações e popular os dados de teste (`seed.sql`):

```powershell
npx supabase db reset
```

### 3.3 Comandos Úteis do Supabase CLI

```powershell
# Aplicar migrações pendentes no ambiente local
npx supabase db push

# Testar Edge Functions localmente
npx supabase functions serve

# Fazer deploy de migrações para o projeto remoto Supabase
npx supabase link --project-ref <ID_DO_SEU_PROJETO>
npx supabase db push

# Fazer deploy de Edge Functions
npx supabase functions deploy <NOME_DA_FUNCAO>
```

---

## 4. Configuração de Variáveis de Ambiente no Flutter

Copie o arquivo de exemplo:

```powershell
Copy-Item .env.example .env
```

Preencha os valores em `.env`:

```ini
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=sua_chave_anonima_publica_aqui
```

> **Aviso Crítico de Segurança**: **NUNCA** adicione a chave `SUPABASE_SERVICE_ROLE_KEY` no aplicativo Flutter ou no arquivo `.env` distribuído no app.

---

## 5. Configuração do Google OAuth

Para login com o Google (Supabase Auth):
1. Acesse o **Google Cloud Console** (https://console.cloud.google.com).
2. Crie um projeto e configure a Tela de Consentimento OAuth (OAuth Consent Screen).
3. Crie Credenciais do tipo **ID do cliente OAuth 2.0**:
   - **Web Application**:
     - URIs de redirecionamento autorizados: Adicione a URL de callback do Supabase: `https://<seu-projeto>.supabase.co/auth/v1/callback` (em dev local: `http://127.0.0.1:54321/auth/v1/callback`).
   - **Android**:
     - Nome do pacote: `com.projeto_nestor.transport_logistics`.
     - Obtenha a impressão digital SHA-1 do certificado de debug:
       ```powershell
       cd android
       ./gradlew signingReport
       ```
   - **iOS / macOS**:
     - Bundle Identifier: `com.projeto_nestor.transportLogistics`.
4. No Dashboard do Supabase (ou em `supabase/config.toml` em dev):
   - Navegue até **Authentication > Providers > Google**.
   - Ative o provedor e insira o **Client ID** e **Client Secret**.

---

## 6. Execução do Projeto Flutter

Para executar no navegador Web:

```powershell
flutter run -d chrome
```

Para executar no Windows Desktop:

```powershell
flutter run -d windows
```

Para executar em dispositivo Android conectado:

```powershell
flutter run -d android
```

---

## 7. Validação de Código e Testes

Antes de submeter código:

```powershell
# Análise de lint e tipagem estática
flutter analyze

# Execução de testes unitários e de integração
flutter test
```
