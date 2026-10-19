import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'connectivity_probe_base.dart';

ConnectivityProbe createConnectivityProbe() => _BrowserProbe();

/// Web: `navigator.onLine` plus the browser's online / offline events
/// (a fetch probe would run into CORS).
class _BrowserProbe implements ConnectivityProbe {
  @override
  Future<bool> check() async => web.window.navigator.onLine;

  @override
  Stream<void> get changes {
    late StreamController<void> controller;
    final listener = ((web.Event _) => controller.add(null)).toJS;
    controller = StreamController<void>.broadcast(
      onListen: () {
        web.window.addEventListener('online', listener);
        web.window.addEventListener('offline', listener);
      },
      onCancel: () {
        web.window.removeEventListener('online', listener);
        web.window.removeEventListener('offline', listener);
      },
    );
    return controller.stream;
  }
}
