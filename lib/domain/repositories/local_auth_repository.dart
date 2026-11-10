import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../../data/local_app_store.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  final LocalAppStore _store;

  LocalAuthRepository(this._store);

  @override
  AppUser? get currentUser => _store.user;

  @override
  Future<void> signIn({required String name, required UserRole role, String? assignedVehicleId}) async {
    _store.signIn(name: name, role: role, assignedVehicleId: assignedVehicleId);
  }

  @override
  Future<void> signOut() async {
    _store.signOut();
  }

  @override
  Stream<AppUser?> get userChanges async* {
    // LocalAppStore is a ChangeNotifier, we expose it as a stream.
    // Emit the current value first.
    yield currentUser;
    // Listen to changes.
    final listener = () => _controller.add(_store.user);
    final _controller = StreamController<AppUser?>();
    _store.addListener(listener);
    try {
      await for (final user in _controller.stream) {
        yield user;
      }
    } finally {
      _store.removeListener(listener);
      await _controller.close();
    }
  }
}

// Provider for LocalAuthRepository
final localAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final store = ref.watch(localAppStoreProvider);
  return LocalAuthRepository(store);
});

