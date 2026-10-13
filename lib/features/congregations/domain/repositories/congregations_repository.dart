import '../entities/congregation.dart';

abstract class CongregationsRepository {
  /// Retorna as congregações ativas vinculadas ao usuário logado
  Future<List<Congregation>> getMyCongregations();

  /// Busca congregação por ID
  Future<Congregation?> getCongregationById(String id);

  /// Retorna a congregação selecionada na sessão atual da interface
  Congregation? get activeCongregation;

  /// Define a congregação ativa no contexto local
  void setActiveCongregation(Congregation congregation);

  /// Limpa a congregação ativa
  void clearActiveCongregation();
}
