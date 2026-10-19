import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../app_update/domain/app_update.dart';
import '../../auth/data/user_document.dart';
import '../../map/data/places_repository.dart';
import '../../map/domain/models/poi_model.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({
    required this.firestore,
    PlacesRepository? placesRepository,
  }) : _places = placesRepository ?? FirestorePlacesRepository(firestore);

  final FirebaseFirestore firestore;
  final PlacesRepository _places;

  /// `whereIn` accepts at most 30 values per query.
  static const _inLimit = 30;

  CollectionReference<Map<String, dynamic>> get _feedback =>
      firestore.collection('admin_feedback');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  @override
  Stream<List<FeedbackEntry>> watchFeedback() {
    return FirestoreAuthGuard.guardedStream<List<FeedbackEntry>>(
      label: 'admin.feedback',
      empty: const [],
      create: () => _feedback
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map(_feedbackFromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return entries;
      }),
    );
  }

  @override
  Stream<List<AdminUserEntry>> watchUsers() {
    return FirestoreAuthGuard.guardedStream<List<AdminUserEntry>>(
      label: 'admin.users',
      empty: const [],
      create: () => _users.snapshots().asyncMap((snapshot) async {
        final emails = await _privateEmails();
        final users = [
          for (final doc in snapshot.docs) _userFromDoc(doc, emails),
        ]
          ..sort((a, b) {
            final left = a.createdAt;
            final right = b.createdAt;
            if (left == null || right == null) {
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }
            return right.compareTo(left);
          });
        return users;
      }),
    );
  }

  @override
  Future<void> resolveFeedback(String feedbackId) {
    return _feedback.doc(feedbackId).update({
      'status': FeedbackEntry.statusResolved,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteFeedback(String feedbackId) {
    return _feedback.doc(feedbackId).delete();
  }

  @override
  Future<String> createPlace(PlaceDraft draft) => _places.createPlace(draft);

  @override
  Future<void> updatePlace(PoiModel poi) => _places.updatePlace(poi);

  @override
  Future<void> deletePlace(String placeId) => _places.deletePlace(placeId);

  // --- Lookups -----------------------------------------------------------------

  Future<Map<String, T>> _fetchByIds<T>(
    String collection,
    Set<String> ids,
    T Function(String id, Map<String, dynamic> data) parse,
    T Function(String id) unknown,
  ) async {
    final wanted = ids.where((id) => id.trim().isNotEmpty).toList();
    final result = <String, T>{for (final id in ids) id: unknown(id)};
    for (var i = 0; i < wanted.length; i += _inLimit) {
      final chunk = wanted.sublist(
        i,
        i + _inLimit > wanted.length ? wanted.length : i + _inLimit,
      );
      try {
        final snap = await firestore
            .collection(collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          result[doc.id] = parse(doc.id, doc.data());
        }
      } catch (error) {
        debugPrint('admin lookup $collection failed: $error');
      }
    }
    return result;
  }

  @override
  Future<Map<String, AdminUserRef>> fetchUsers(Set<String> uids) {
    return _fetchByIds(
      userCollection,
      uids,
      (id, data) => AdminUserRef(
        uid: id,
        name: (data['name'] as String? ?? '').trim(),
        photoUrl: _userPhoto(data),
        role: data['role'] as String? ?? AdminRoles.user,
      ),
      AdminUserRef.unknown,
    );
  }

  @override
  Future<Map<String, AdminDogRef>> fetchDogs(Set<String> dogIds) {
    return _fetchByIds('dogs', dogIds, _dogFromMap, AdminDogRef.unknown);
  }

  @override
  Future<Map<String, AdminMomentRef>> fetchMoments(Set<String> momentIds) {
    return _fetchByIds(
      'moments',
      momentIds,
      (id, data) => AdminMomentRef(
        id: id,
        caption: (data['caption'] as String? ?? '').trim(),
        photoUrl: data['momentPhotoUrl'] as String? ?? '',
        authorUserId: data['authorUserId'] as String? ?? '',
        dogName: data['dogName'] as String? ?? '',
      ),
      AdminMomentRef.unknown,
    );
  }

  @override
  Future<AdminMessageRef> fetchChatMessage(
    String chatId,
    String messageId,
  ) async {
    if (chatId.isEmpty || messageId.isEmpty) {
      return AdminMessageRef.unknown(chatId, messageId);
    }
    try {
      final doc = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      final data = doc.data();
      if (data == null) return AdminMessageRef.unknown(chatId, messageId);
      return AdminMessageRef(
        chatId: chatId,
        id: messageId,
        text: (data['text'] as String? ?? '').trim(),
        senderId: data['senderId'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
      );
    } catch (error) {
      debugPrint('admin message lookup failed: $error');
      return AdminMessageRef.unknown(chatId, messageId);
    }
  }

  @override
  Future<List<AdminDogRef>> fetchUserDogs(String uid) async {
    try {
      final snap = await firestore
          .collection('dogs')
          .where('ownerId', isEqualTo: uid)
          .get();
      return [for (final doc in snap.docs) _dogFromMap(doc.id, doc.data())];
    } catch (error) {
      debugPrint('admin user dogs failed: $error');
      return const [];
    }
  }

  // --- Dashboard ---------------------------------------------------------------

  Future<int?> _count(String label, Query<Map<String, dynamic>> query) async {
    try {
      final snap = await query.count().get();
      return snap.count;
    } catch (error) {
      debugPrint('admin stat $label unavailable: $error');
      return null;
    }
  }

  @override
  Future<AdminStats> loadStats() async {
    final now = DateTime.now();
    Timestamp ago(int days) =>
        Timestamp.fromDate(now.subtract(Duration(days: days)));
    final nowTs = Timestamp.fromDate(now);
    final walkLedger = firestore
        .collectionGroup('reward_ledger')
        .where('type', isEqualTo: 'walk');
    final claims = firestore.collection('coupon_claims');

    Future<int?> walkKm() async {
      try {
        final snap = await walkLedger.aggregate(sum('km')).get();
        return snap.getSum('km')?.round();
      } catch (error) {
        debugPrint('admin stat walkKm unavailable: $error');
        return null;
      }
    }

    final results = await Future.wait<int?>([
      _count('users', _users),
      _count('newUsers7', _users.where('createdAt', isGreaterThanOrEqualTo: ago(7))),
      _count('newUsers30', _users.where('createdAt', isGreaterThanOrEqualTo: ago(30))),
      _count('dogs', firestore.collection('dogs')),
      _count('matches', firestore.collection('matches')),
      _count(
        'activeChats7',
        firestore
            .collection('chats')
            .where('lastMessageTimestamp', isGreaterThanOrEqualTo: ago(7)),
      ),
      _count(
        'stories',
        firestore.collection('stories').where('expiresAt', isGreaterThan: nowTs),
      ),
      _count('moments', firestore.collection('moments')),
      _count(
        'lostDogs',
        firestore.collection('lost_dogs').where('status', isEqualTo: 'active'),
      ),
      _count(
        'adoption',
        firestore
            .collection('adoption_dogs')
            .where('status', isEqualTo: 'available'),
      ),
      _count(
        'events',
        firestore
            .collection('events')
            .where('dateTime', isGreaterThanOrEqualTo: nowTs),
      ),
      _count(
        'groupsPending',
        firestore.collection('breed_groups').where('isApproved', isEqualTo: false),
      ),
      _count('walks', walkLedger),
      walkKm(),
      _count('claimed', claims.where('status', isEqualTo: 'claimed')),
      _count('redeemed', claims.where('status', isEqualTo: 'redeemed')),
      _count('partners', firestore.collection('partners')),
      _count('suspended', _users.where('isSuspended', isEqualTo: true)),
    ]);
    return AdminStats(
      users: results[0],
      newUsers7: results[1],
      newUsers30: results[2],
      dogs: results[3],
      matches: results[4],
      activeChats7: results[5],
      activeStories: results[6],
      moments: results[7],
      lostDogsActive: results[8],
      adoptionsAvailable: results[9],
      eventsUpcoming: results[10],
      groupsPending: results[11],
      walks: results[12],
      walkKm: results[13],
      couponsClaimed: results[14],
      couponsRedeemed: results[15],
      partners: results[16],
      suspendedUsers: results[17],
    );
  }

  // --- Users -------------------------------------------------------------------

  @override
  Future<void> setUserRole(
    String uid, {
    required String role,
    String partnerId = '',
  }) {
    if (role != AdminRoles.user && role != AdminRoles.partner) {
      throw ArgumentError.value(role, 'role', 'only user / partner');
    }
    if (role == AdminRoles.partner && partnerId.isEmpty) {
      throw ArgumentError.value(partnerId, 'partnerId', 'required');
    }
    return _users.doc(uid).update({
      'role': role,
      'partnerId':
          role == AdminRoles.partner ? partnerId : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setUserSuspended(
    String uid, {
    required bool suspended,
    String reason = '',
  }) {
    return _users.doc(uid).update({
      'isSuspended': suspended ? true : FieldValue.delete(),
      'suspendedReason':
          suspended && reason.trim().isNotEmpty ? reason.trim() : FieldValue.delete(),
      'suspendedAt':
          suspended ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Moderation --------------------------------------------------------------

  @override
  Future<void> deleteDog(String dogId) {
    return firestore.collection('dogs').doc(dogId).delete();
  }

  @override
  Future<void> deleteChatMessage(String chatId, String messageId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // --- Listings ----------------------------------------------------------------

  static String _collectionOf(AdminContentKind kind) => switch (kind) {
        AdminContentKind.lostDog => 'lost_dogs',
        AdminContentKind.adoption => 'adoption_dogs',
        AdminContentKind.event => 'events',
        AdminContentKind.group => 'breed_groups',
      };

  @override
  Stream<List<AdminContentItem>> watchContent(AdminContentKind kind) {
    final col = firestore.collection(_collectionOf(kind));
    final query = kind == AdminContentKind.event
        ? col.orderBy('dateTime', descending: true).limit(200)
        : col.limit(300);
    return FirestoreAuthGuard.guardedStream<List<AdminContentItem>>(
      label: 'admin.content.${kind.name}',
      empty: const [],
      create: () => query.snapshots().map((snap) {
        final items = [
          for (final doc in snap.docs) contentFromMap(kind, doc.id, doc.data()),
        ]..sort((a, b) {
            final l = a.createdAt;
            final r = b.createdAt;
            if (l == null || r == null) return a.title.compareTo(b.title);
            return r.compareTo(l);
          });
        return items;
      }),
    );
  }

  @override
  Future<void> closeContent(AdminContentKind kind, String id) {
    final doc = firestore.collection(_collectionOf(kind)).doc(id);
    return switch (kind) {
      AdminContentKind.lostDog => doc.update({'status': 'resolved'}),
      AdminContentKind.adoption => doc.update({'status': 'adopted'}),
      AdminContentKind.group => doc.update({'isApproved': true}),
      AdminContentKind.event => Future<void>.value(),
    };
  }

  @override
  Future<void> deleteContent(AdminContentKind kind, String id) {
    return firestore.collection(_collectionOf(kind)).doc(id).delete();
  }

  /// Maps a listing document (also used by tests with fake data).
  @visibleForTesting
  static AdminContentItem contentFromMap(
    AdminContentKind kind,
    String id,
    Map<String, dynamic> data,
  ) {
    String s(String key) => (data[key] as String? ?? '').trim();
    final created = _dateOf(data['createdAt']);
    switch (kind) {
      case AdminContentKind.lostDog:
        return AdminContentItem(
          kind: kind,
          id: id,
          title: s('dogName'),
          subtitle: [s('breed'), s('city'), s('neighborhood')]
              .where((v) => v.isNotEmpty)
              .join(' · '),
          imageUrl: s('imageUrl'),
          ownerId: s('uploaderUserId'),
          status: s('status').isEmpty ? 'active' : s('status'),
          createdAt: created ?? _dateOf(data['lostDate']),
        );
      case AdminContentKind.adoption:
        final images = data['imageUrls'];
        return AdminContentItem(
          kind: kind,
          id: id,
          title: s('name'),
          subtitle: [s('breed'), s('location')]
              .where((v) => v.isNotEmpty)
              .join(' · '),
          imageUrl: images is List && images.isNotEmpty ? '${images.first}' : '',
          ownerId: s('uploaderUserId'),
          status: s('status').isEmpty ? 'available' : s('status'),
          createdAt: created,
        );
      case AdminContentKind.event:
        final at = _dateOf(data['dateTime']);
        return AdminContentItem(
          kind: kind,
          id: id,
          title: s('title'),
          subtitle: s('locationName'),
          imageUrl: s('imageUrl'),
          ownerId: s('organizerUserId'),
          status: at != null && at.isAfter(DateTime.now()) ? 'upcoming' : 'past',
          createdAt: at ?? created,
        );
      case AdminContentKind.group:
        return AdminContentItem(
          kind: kind,
          id: id,
          title: s('title'),
          subtitle: s('description'),
          imageUrl: s('imageUrl'),
          ownerId: s('createdBy'),
          status: data['isApproved'] == false ? 'pending' : 'approved',
          createdAt: created,
        );
    }
  }

  // --- app_config --------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> get _appConfig =>
      firestore.doc('app_config/android');

  @override
  Future<AppUpdateConfig?> fetchAppConfig() async {
    final snap = await _appConfig.get();
    return snap.exists ? AppUpdateConfig.fromMap(snap.data()) : null;
  }

  @override
  Future<void> saveAppConfig(AppUpdateConfig config) {
    return _appConfig.set({
      'minBuild': config.minBuild,
      'latestBuild': config.latestBuild,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- Helpers -----------------------------------------------------------------

  FeedbackEntry _feedbackFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['userName'] as String? ?? '').trim();
    final status = (data['status'] as String? ?? '').trim();
    return FeedbackEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: name.isEmpty ? 'Korisnik' : name,
      userEmail: data['userEmail'] as String? ?? '',
      category: data['category'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: status.isEmpty ? FeedbackEntry.statusNew : status,
      createdAt: doc.metadata.hasPendingWrites
          ? DateTime.now()
          : _dateOf(data['createdAt']) ?? DateTime.now(),
    );
  }

  /// uid → email from `users/{uid}/private/account` (admin-only read).
  Future<Map<String, String>> _privateEmails() async {
    try {
      final snapshot =
          await firestore.collectionGroup(userPrivateCollection).get();
      return {
        for (final doc in snapshot.docs)
          if (doc.reference.parent.parent != null)
            doc.reference.parent.parent!.id:
                doc.data()['email'] as String? ?? '',
      };
    } catch (_) {
      return const {};
    }
  }

  AdminUserEntry _userFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> emails,
  ) {
    final data = doc.data();
    final name = (data['name'] as String? ?? '').trim();
    final city = (data['cityName'] as String? ?? '').trim();
    return AdminUserEntry(
      uid: data['uid'] as String? ?? doc.id,
      name: name.isEmpty ? 'Korisnik' : name,
      // Legacy docs may still carry email until the owner's next sign-in.
      email: emails[doc.id] ?? data['email'] as String? ?? '',
      role: data['role'] as String? ?? AdminRoles.user,
      createdAt: _dateOf(data['createdAt']),
      photoUrl: _userPhoto(data),
      city: city.isNotEmpty ? city : (data['city'] as String? ?? '').trim(),
      partnerId: (data['partnerId'] as String? ?? '').trim(),
      isSuspended: data['isSuspended'] == true,
      suspendedReason: (data['suspendedReason'] as String? ?? '').trim(),
    );
  }

  static String _userPhoto(Map<String, dynamic> data) {
    final custom = (data['customPhotoUrl'] as String? ?? '').trim();
    if (custom.isNotEmpty) return custom;
    return (data['photoUrl'] as String? ?? '').trim();
  }

  static AdminDogRef _dogFromMap(String id, Map<String, dynamic> data) {
    String photo() {
      for (final key in const ['primaryPhotoUrl', 'photoUrl', 'imageUrl']) {
        final v = (data[key] as String? ?? '').trim();
        if (v.isNotEmpty) return v;
      }
      final list = data['photoUrls'] ?? data['photos'];
      return list is List && list.isNotEmpty ? '${list.first}' : '';
    }

    return AdminDogRef(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      breed: (data['breed'] as String? ?? '').trim(),
      photoUrl: photo(),
      ownerId: data['ownerId'] as String? ?? '',
    );
  }

  static DateTime? _dateOf(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
