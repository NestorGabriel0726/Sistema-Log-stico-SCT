# Checklist Staging (Supabase remoto)

Use após validar localmente com `scripts/validate-dev.ps1`.

1. Criar projeto **Staging** no Supabase Dashboard.
2. `npx supabase link --project-ref <REF_STAGING>`
3. `npx supabase db push` (somente migrations versionadas).
4. Configurar Google OAuth no projeto staging (mesmas URIs de callback do ambiente).
5. Executar build Flutter Web apontando para staging:

```powershell
flutter build web `
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon_key_staging>
```

6. Homologar fluxos: login, convites, lista de eventos, dashboard e RLS financeiro com perfil de capitão.

Consulte também [deployment.md](deployment.md).
