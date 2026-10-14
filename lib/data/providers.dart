import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_app_store.dart';

final localStoreProvider = ChangeNotifierProvider<LocalAppStore>((ref) {
  return LocalAppStore();
});
