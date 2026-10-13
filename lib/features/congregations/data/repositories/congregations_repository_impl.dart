import '../../domain/entities/congregation.dart';
import '../../domain/repositories/congregations_repository.dart';
import '../datasources/congregations_remote_data_source.dart';

class CongregationsRepositoryImpl implements CongregationsRepository {
  final CongregationsRemoteDataSource _remoteDataSource;
  Congregation? _activeCongregation;

  CongregationsRepositoryImpl({required this._remoteDataSource});

  @override
  Congregation? get activeCongregation => _activeCongregation;

  @override
  void setActiveCongregation(Congregation congregation) {
    _activeCongregation = congregation;
  }

  @override
  void clearActiveCongregation() {
    _activeCongregation = null;
  }

  @override
  Future<List<Congregation>> getMyCongregations() async {
    final list = await _remoteDataSource.getMyCongregations();
    // Se a congregação ativa atual não estiver na lista ou for nula, ajustar
    if (_activeCongregation != null) {
      final exists = list.any((c) => c.id == _activeCongregation!.id);
      if (!exists) {
        _activeCongregation = list.isNotEmpty ? list.first : null;
      }
    } else if (list.length == 1) {
      _activeCongregation = list.first;
    }
    return list;
  }

  @override
  Future<Congregation?> getCongregationById(String id) {
    return _remoteDataSource.getCongregationById(id);
  }
}
