import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/data/user_document.dart';

class PoiReports extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void report(String id) {
    state = {...state, id};
  }

  /// Persists a place-change report for admin review.
  ///
  /// Fast path writes only to the signed-in user document (allowed in prod),
  /// then mirrors to other collections in the background.
  Future<void> submitChangeRequest({
    required String placeId,
    required String placeName,
    required String changeType,
    required String description,
    bool markAsReported = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = (user?.uid ?? '').trim();
    debugPrint(
      'POI change report: uid=${uid.isEmpty ? "(none)" : uid} '
      'firebaseReady=$isFirebaseReady auth=${user != null}',
    );
    if (uid.isEmpty) {
      throw StateError('Morate biti prijavljeni da biste poslali prijavu.');
    }

    final trimmedPlaceId = placeId.trim();
    final trimmedPlaceName = placeName.trim();
    final trimmedType = changeType.trim();
    final trimmedDescription = description.trim();
    final requestId = 'pcr-${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = Timestamp.now();

    final entry = <String, Object?>{
      'id': requestId,
      'placeId': trimmedPlaceId,
      'placeName': trimmedPlaceName,
      'reportedByUserId': uid,
      'changeType': trimmedType,
      'description': trimmedDescription,
      'createdAt': createdAt,
      'status': 'pending',
    };

    if (!isFirebaseReady) {
      debugPrint(
        'POI change_request (local): '
        '$trimmedPlaceId / $trimmedType / $trimmedDescription',
      );
      if (markAsReported) {
        report(trimmedPlaceId);
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;

    // Fast path — unblock UI immediately after this write.
    // Private doc: the public users/{uid} is readable by everyone.
    await setUserPrivateFields(firestore, uid, {
      'placeChangeRequests': FieldValue.arrayUnion([entry]),
    });
    debugPrint('POI change report saved on users/$uid/private');

    if (markAsReported) {
      report(trimmedPlaceId);
    }

    unawaited(_mirrorChangeRequest(
      firestore: firestore,
      uid: uid,
      entry: entry,
      trimmedPlaceId: trimmedPlaceId,
      trimmedPlaceName: trimmedPlaceName,
      trimmedType: trimmedType,
      trimmedDescription: trimmedDescription,
      requestId: requestId,
    ));
  }

  Future<void> _mirrorChangeRequest({
    required FirebaseFirestore firestore,
    required String uid,
    required Map<String, Object?> entry,
    required String trimmedPlaceId,
    required String trimmedPlaceName,
    required String trimmedType,
    required String trimmedDescription,
    required String requestId,
  }) async {
    try {
      await firestore.collection('notifications').add({
        'type': 'PLACE_CHANGE_REQUEST',
        'title': 'Prijava promene lokacije',
        'message': '$trimmedType — $trimmedPlaceName',
        'body': trimmedDescription.isEmpty ? trimmedType : trimmedDescription,
        'recipientId': uid,
        'toUserId': uid,
        'senderId': uid,
        'fromUserId': uid,
        'reportedByUserId': uid,
        'placeId': trimmedPlaceId,
        'placeName': trimmedPlaceName,
        'changeType': trimmedType,
        'description': trimmedDescription,
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'status': 'pending',
      });
    } catch (error) {
      debugPrint('notifications mirror skipped: $error');
    }

    for (final collection in [
      'change_requests',
      'admin_notifications',
      'reports',
    ]) {
      try {
        final payload = <String, Object?>{
          ...entry,
          'createdAt': FieldValue.serverTimestamp(),
          if (collection == 'reports') ...{
            'reporterId': uid,
            'reportedBy': uid,
            'reportedUserId': '',
            'targetType': 'poi',
            'targetId': trimmedPlaceId,
            'reason': trimmedType,
            'details': trimmedDescription,
            'timestamp': FieldValue.serverTimestamp(),
          },
          if (collection == 'admin_notifications') ...{
            'type': 'PLACE_CHANGE_REQUEST',
            'targetId': trimmedPlaceId,
            'targetType': 'poi',
            'reason': trimmedType,
            'details': trimmedDescription,
          },
        };
        await firestore.collection(collection).add(payload);
      } catch (error) {
        debugPrint('$collection mirror skipped: $error');
      }
    }
  }
}

final poiReportsProvider =
    NotifierProvider<PoiReports, Set<String>>(PoiReports.new);

/// Places the community has confirmed as checked / still accurate.
class PoiConfirmations extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void confirm(String id) {
    state = {...state, id};
  }
}

final poiConfirmationsProvider =
    NotifierProvider<PoiConfirmations, Set<String>>(PoiConfirmations.new);
