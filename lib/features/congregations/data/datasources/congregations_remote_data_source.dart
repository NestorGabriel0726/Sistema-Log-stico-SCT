import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/congregation_model.dart';

abstract class CongregationsRemoteDataSource {
  Future<List<CongregationModel>> getMyCongregations();
  Future<CongregationModel?> getCongregationById(String id);
}

class CongregationsRemoteDataSourceImpl implements CongregationsRemoteDataSource {
  final SupabaseClient _client;

  CongregationsRemoteDataSourceImpl({required this._client});

  @override
  Future<List<CongregationModel>> getMyCongregations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // 1. Tentar via Database RPC
      final rpcRes = await _client.rpc('get_my_congregations');
      if (rpcRes is List) {
        return rpcRes
            .map((item) => CongregationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback para select direto respeitando RLS
    }

    try {
      final res = await _client
          .from('congregation_members')
          .select('role, status, congregations(*)')
          .eq('user_id', user.id)
          .eq('status', 'ACTIVE');

      final list = <CongregationModel>[];
      for (final item in (res as List)) {
        final congMap = item['congregations'] as Map<String, dynamic>?;
        if (congMap != null) {
          final merged = Map<String, dynamic>.from(congMap);
          merged['member_role'] = item['role'];
          merged['status'] = item['status'];
          list.add(CongregationModel.fromJson(merged));
        }
      }
      return list;
    } catch (e) {
      throw DomainFailure('Erro ao listar congregações vinculadas: $e');
    }
  }

  @override
  Future<CongregationModel?> getCongregationById(String id) async {
    try {
      final res = await _client
          .from('congregations')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return CongregationModel.fromJson(res);
    } catch (e) {
      throw DomainFailure('Erro ao buscar congregação: $e');
    }
  }
}
