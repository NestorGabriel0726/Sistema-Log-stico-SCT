import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/backend_mode.dart';
import '../../core/config/supabase_client.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_allocations_repository.dart';
import '../../data/repositories/local_check_in_repository.dart';
import '../../data/repositories/local_events_repository.dart';
import '../../data/repositories/local_passages_repository.dart';
import '../../data/repositories/local_passengers_repository.dart';
import '../../data/repositories/local_receipts_repository.dart';
import '../../data/repositories/local_vehicles_repository.dart';
import '../../data/repositories/supabase_allocations_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_check_in_repository.dart';
import '../../data/repositories/supabase_events_repository.dart';
import '../../data/repositories/supabase_passages_repository.dart';
import '../../data/repositories/supabase_passengers_repository.dart';
import '../../data/repositories/supabase_receipts_repository.dart';
import '../../data/repositories/supabase_vehicles_repository.dart';
import 'allocations_repository.dart';
import 'auth_repository.dart';
import 'check_in_repository.dart';
import 'events_repository.dart';
import 'local_auth_repository.dart';
import 'passages_repository.dart';
import 'passengers_repository.dart';
import 'receipts_repository.dart';
import 'vehicles_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseAuthRepository(client);
  }
  return LocalAuthRepository(ref.watch(localStoreProvider));
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseEventsRepository(client);
  }
  return LocalEventsRepository(ref.watch(localStoreProvider));
});

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseVehiclesRepository(client);
  }
  return LocalVehiclesRepository(ref.watch(localStoreProvider));
});

final passengersRepositoryProvider = Provider<PassengersRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabasePassengersRepository(client);
  }
  return LocalPassengersRepository(ref.watch(localStoreProvider));
});

final passagesRepositoryProvider = Provider<PassagesRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabasePassagesRepository(client);
  }
  return LocalPassagesRepository(ref.watch(localStoreProvider));
});

final allocationsRepositoryProvider = Provider<AllocationsRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseAllocationsRepository(client);
  }
  return LocalAllocationsRepository(ref.watch(localStoreProvider));
});

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseCheckInRepository(client);
  }
  return LocalCheckInRepository(ref.watch(localStoreProvider));
});

final receiptsRepositoryProvider = Provider<ReceiptsRepository>((ref) {
  if (ref.watch(backendModeProvider) == BackendMode.supabase) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) return SupabaseReceiptsRepository(client);
  }
  return LocalReceiptsRepository();
});
