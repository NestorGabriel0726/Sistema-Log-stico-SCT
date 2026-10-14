# Transporte SCT

App Flutter **local** para gestão de transporte de congregação em assembleias e congressos. Sem Supabase nesta fase: os dados ficam neste aparelho e sobrevivem ao fechar o app.

## O que já funciona

- Quatro perfis: coordenador, ajudante do coordenador, capitão e ajudante do capitão
- CRUD de eventos, prazos, valor da diária e idade mínima de cobrança
- Veículos com capacidade física × limite local
- Passagens (quem paga) vs passageiros (quem viaja), dias individuais, PIX/espécie, comprovante em texto
- Autocomplete de nomes já cadastrados e bloqueio de isenção se a criança já tiver a idade na data do evento
- Listas numeradas, alocação, desistência (vaga seca ou substituto) e realocação entre ônibus
- Filtros em passagens e passageiros
- Dashboard com financeiro, gráfico por dia e lotação
- Check-in ida/volta com toggle por perfil
- Histórico de alterações
- Persistência local (`shared_preferences`)

A pasta `supabase/` permanece no repositório para o amigo ligar o banco **depois**, na máquina dele.

## Rodar

```powershell
flutter pub get
flutter run -d windows
# ou: flutter run -d chrome
```

Se o Flutter não estiver no PATH:

```powershell
.\scripts\run.ps1
```
