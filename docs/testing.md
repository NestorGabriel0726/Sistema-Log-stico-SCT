# Estratégia e Guia de Testes (docs/testing.md)

Este documento descreve os níveis de testes implementados no sistema e os procedimentos para execução.

---

## 1. Níveis de Testes

### 1.1 Testes Unitários (Flutter / Dart)
Focados em lógica de domínio e validação pura sem dependência externa de rede:
- **Cálculo de idade no dia do evento** (aniversário antes, no dia e depois do evento);
- **Regra de isenção por idade** (abaixo da idade mínima = isento; igual ou acima = pagante);
- **Cálculo financeiro de passagens** (soma dos dias de viagem x diária);
- **Status financeiro** (`UNPAID`, `PARTIALLY_PAID`, `PAID`, `OVERPAID`, `NOT_APPLICABLE`);
- **Formatação monetária e de documentos**.

### 1.2 Testes de Banco de Dados e Concorrência (PostgreSQL)
Validados no Supabase Local:
- **Capacidade máxima do veículo**: Dois usuários tentando alocar a 30ª vaga simultaneamente (Usuário A obtém sucesso, Usuário B recebe `VEHICLE_FULL`, nunca 31/30);
- **Transferência Atômica**: Transferência entre veículos sem perda de histórico e sem duplicidade;
- **RLS**: Garantia de que Capitão não consegue ler a tabela `payments` ou o bucket `payment-receipts`.

---

## 2. Como Executar os Testes

```powershell
# Executar todos os testes do Flutter
flutter test

# Executar com relatório de cobertura
flutter test --coverage
```
