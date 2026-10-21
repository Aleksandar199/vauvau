import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/app_update.dart';

abstract class AppUpdateRepository {
  /// Null when the config cannot be read (offline, rules not deployed):
  /// no prompt is shown then.
  Future<AppUpdateConfig?> fetch(AppStorePlatform platform);
}

class FirestoreAppUpdateRepository implements AppUpdateRepository {
  FirestoreAppUpdateRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AppUpdateConfig?> fetch(AppStorePlatform platform) async {
    try {
      final snapshot =
          await _firestore.doc('app_config/${platform.configDocId}').get();
      return snapshot.exists ? AppUpdateConfig.fromMap(snapshot.data()) : null;
    } catch (error) {
      debugPrint('app update config unavailable: $error');
      return null;
    }
  }
}

class LocalAppUpdateRepository implements AppUpdateRepository {
  LocalAppUpdateRepository([this.config]);

  final AppUpdateConfig? config;

  @override
  Future<AppUpdateConfig?> fetch(AppStorePlatform platform) async => config;
}
