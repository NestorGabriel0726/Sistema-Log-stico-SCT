/// Lógica e regras de negócio de domínio puras.
/// Mantida em consonância estrita com as funções SQL correspondentes no PostgreSQL.
abstract class DomainCalculations {
  /// Calcula a idade exata de uma pessoa na data de referência do evento (Regra 22).
  /// Nunca calcula com base na data de cadastro!
  static int calculateAgeOnDate({
    required DateTime birthDate,
    required DateTime targetDate,
  }) {
    int age = targetDate.year - birthDate.year;
    if (targetDate.month < birthDate.month ||
        (targetDate.month == birthDate.month && targetDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Determina se uma pessoa tem direito à isenção por idade na data do evento (Regra 22).
  /// Ex: se minimumPayingAge = 6, criança com 5 anos é isenta; criança com 6 anos já é pagante.
  static bool isExemptByAge({
    required DateTime birthDate,
    required DateTime eventDate,
    required int minimumPayingAge,
  }) {
    final age = calculateAgeOnDate(birthDate: birthDate, targetDate: eventDate);
    return age < minimumPayingAge;
  }

  /// Mensagem explicativa de elegibilidade de isenção por idade.
  static String ageEligibilityMessage({
    required DateTime? birthDate,
    required DateTime eventDate,
    required int minimumPayingAge,
    required String eventTheme,
  }) {
    if (birthDate == null) {
      return 'Data de nascimento não informada: o cálculo da isenção ainda não pode ser realizado.';
    }
    final age = calculateAgeOnDate(birthDate: birthDate, targetDate: eventDate);
    if (age < minimumPayingAge) {
      return 'Isento de pagamento: a idade na data do $eventTheme será de $age anos, inferior à idade mínima para cobrança de $minimumPayingAge anos.';
    } else {
      return 'A idade na data do $eventTheme será de $age anos. Como é igual ou superior à idade mínima para cobrança de $minimumPayingAge anos, o valor da passagem deve ser cobrado.';
    }
  }

  /// Calcula o valor devido (em centavos) de um passageiro individual para o evento (Regra 33).
  static int calculatePassengerDueCents({
    required int selectedDaysCount,
    required int dailyFareCents,
    required bool isExempt,
  }) {
    if (isExempt) return 0;
    if (selectedDaysCount <= 0 || dailyFareCents <= 0) return 0;
    return selectedDaysCount * dailyFareCents;
  }

  /// Determina o status financeiro de uma passagem (Regra 34).
  static String calculateFinancialStatus({
    required int expectedCents,
    required int paidCents,
  }) {
    if (expectedCents == 0) return 'NOT_APPLICABLE';
    if (paidCents <= 0) return 'UNPAID';
    if (paidCents < expectedCents) return 'PARTIALLY_PAID';
    if (paidCents == expectedCents) return 'PAID';
    return 'OVERPAID';
  }
}
