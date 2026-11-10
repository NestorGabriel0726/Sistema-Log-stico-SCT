import 'dart:async';

import 'package:flutter/foundation.dart';

/// Turns a [ChangeNotifier] into a broadcast stream that emits [read] now
/// and again whenever the notifier fires.
Stream<T> storeChangeStream<T>(ChangeNotifier notifier, T Function() read) {
  late StreamController<T> controller;
  void emit() {
    if (!controller.isClosed) {
      controller.add(read());
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      emit();
      notifier.addListener(emit);
    },
    onCancel: () {
      notifier.removeListener(emit);
    },
  );
  return controller.stream;
}
