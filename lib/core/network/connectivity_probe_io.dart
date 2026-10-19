import 'dart:io';

import 'connectivity_probe_base.dart';

ConnectivityProbe createConnectivityProbe() => const _DnsProbe();

/// Android / iOS: a DNS lookup of the hosts the app itself needs. It fails
/// offline (also on Wi-Fi without internet) and costs almost nothing.
class _DnsProbe implements ConnectivityProbe {
  const _DnsProbe();

  static const _hosts = ['firestore.googleapis.com', 'www.google.com'];

  @override
  Future<bool> check() async {
    for (final host in _hosts) {
      try {
        final found = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 4));
        if (found.isNotEmpty && found.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Try the next host.
      }
    }
    return false;
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}
