# Setup — MVP local (sem Supabase)

## Rodar

```powershell
flutter pub get
flutter run -d windows
```

Ou `.\scripts\run.ps1` se o Flutter estiver em `.tools/flutter`.

## O que testar

1. Entre como **Coordenador**.
2. Abra o congresso de exemplo.
3. Visão geral: financeiro, gráfico por dia, prazos.
4. Ônibus: troque o dia, aloque, desista, realoque.
5. Passagens: filtros e **Nova passagem** (prazo do seed já passou — deve pedir bypass).
6. Passageiros: filtros A–Z, documento, isento.
7. Configurações: toggle de check-in do capitão.
8. Feche e abra de novo: os dados devem continuar (persistência local).
9. Entre de novo como **Capitão**: financeiro some; check-in depende do toggle.

## Supabase

Não ligue agora. A pasta `supabase/` fica para o amigo configurar na máquina dele depois.
