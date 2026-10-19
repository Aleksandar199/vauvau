import 'dart:async';

import '../../app_update/domain/app_update.dart';
import '../../map/data/places_repository.dart';
import '../../map/domain/models/poi_model.dart';
import '../../support/domain/admin_feedback.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

/// In-memory admin data used when Firebase is not configured (local dev runs
/// and widget tests).
class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository({
    List<FeedbackEntry>? feedback,
    List<AdminUserEntry>? users,
    List<AdminDogRef>? dogs,
    List<AdminMomentRef>? moments,
    List<AdminMessageRef>? messages,
    Map<AdminContentKind, List<AdminContentItem>>? content,
    this.stats = const AdminStats(),
    this.appConfig,
    PlacesRepository? placesRepository,
  })  : _feedback = List<FeedbackEntry>.from(feedback ?? _seedFeedback()),
        _users = List<AdminUserEntry>.from(users ?? _seedUsers()),
        _dogs = {for (final d in dogs ?? const <AdminDogRef>[]) d.id: d},
        _moments = {
          for (final m in moments ?? const <AdminMomentRef>[]) m.id: m,
        },
        _messages = {
          for (final m in messages ?? const <AdminMessageRef>[])
            '${m.chatId}/${m.id}': m,
        },
        _content = {
          for (final kind in AdminContentKind.values)
            kind: List<AdminContentItem>.from(content?[kind] ?? const []),
        },
        _places = placesRepository ?? LocalPlacesRepository();

  final List<FeedbackEntry> _feedback;
  final List<AdminUserEntry> _users;
  final Map<String, AdminDogRef> _dogs;
  final Map<String, AdminMomentRef> _moments;
  final Map<String, AdminMessageRef> _messages;
  final Map<AdminContentKind, List<AdminContentItem>> _content;
  final AdminStats stats;
  AppUpdateConfig? appConfig;
  final PlacesRepository _places;
  final StreamController<List<FeedbackEntry>> _feedbackController =
      StreamController<List<FeedbackEntry>>.broadcast();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Lookup batches (tests check that ids are fetched together).
  final List<Set<String>> userLookups = [];

  void dispose() {
    _feedbackController.close();
    _changes.close();
  }

  List<AdminUserEntry> get users => List.unmodifiable(_users);

  bool hasDog(String id) => _dogs.containsKey(id);

  bool hasMessage(String chatId, String id) =>
      _messages.containsKey('$chatId/$id');

  @override
  Stream<List<FeedbackEntry>> watchFeedback() async* {
    yield _sortedFeedback();
    yield* _feedbackController.stream;
  }

  @override
  Stream<List<AdminUserEntry>> watchUsers() async* {
    yield List<AdminUserEntry>.from(_users);
    yield* _changes.stream.map((_) => List<AdminUserEntry>.from(_users));
  }

  @override
  Future<void> resolveFeedback(String feedbackId) async {
    for (var i = 0; i < _feedback.length; i++) {
      if (_feedback[i].id == feedbackId) {
        _feedback[i] = _feedback[i].copyWith(
          status: FeedbackEntry.statusResolved,
        );
      }
    }
    _feedbackController.add(_sortedFeedback());
  }

  @override
  Future<void> deleteFeedback(String feedbackId) async {
    _feedback.removeWhere((entry) => entry.id == feedbackId);
    _feedbackController.add(_sortedFeedback());
  }

  @override
  Future<String> createPlace(PlaceDraft draft) => _places.createPlace(draft);

  @override
  Future<void> updatePlace(PoiModel poi) => _places.updatePlace(poi);

  @override
  Future<void> deletePlace(String placeId) => _places.deletePlace(placeId);

  @override
  Future<Map<String, AdminUserRef>> fetchUsers(Set<String> uids) async {
    userLookups.add(Set.of(uids));
    return {
      for (final uid in uids)
        uid: () {
          for (final u in _users) {
            if (u.uid == uid) {
              return AdminUserRef(
                uid: uid,
                name: u.name,
                photoUrl: u.photoUrl,
                role: u.role,
              );
            }
          }
          return AdminUserRef.unknown(uid);
        }(),
    };
  }

  @override
  Future<Map<String, AdminDogRef>> fetchDogs(Set<String> dogIds) async => {
        for (final id in dogIds) id: _dogs[id] ?? AdminDogRef.unknown(id),
      };

  @override
  Future<Map<String, AdminMomentRef>> fetchMoments(
    Set<String> momentIds,
  ) async =>
      {
        for (final id in momentIds)
          id: _moments[id] ?? AdminMomentRef.unknown(id),
      };

  @override
  Future<AdminMessageRef> fetchChatMessage(
    String chatId,
    String messageId,
  ) async =>
      _messages['$chatId/$messageId'] ??
      AdminMessageRef.unknown(chatId, messageId);

  @override
  Future<List<AdminDogRef>> fetchUserDogs(String uid) async => [
        for (final d in _dogs.values)
          if (d.ownerId == uid) d,
      ];

  @override
  Future<AdminStats> loadStats() async => stats;

  @override
  Future<void> setUserRole(
    String uid, {
    required String role,
    String partnerId = '',
  }) async {
    if (role != AdminRoles.user && role != AdminRoles.partner) {
      throw ArgumentError.value(role, 'role', 'only user / partner');
    }
    _updateUser(
      uid,
      (u) => u.copyWith(
        role: role,
        partnerId: role == AdminRoles.partner ? partnerId : '',
      ),
    );
  }

  @override
  Future<void> setUserSuspended(
    String uid, {
    required bool suspended,
    String reason = '',
  }) async {
    _updateUser(
      uid,
      (u) => u.copyWith(
        isSuspended: suspended,
        suspendedReason: suspended ? reason.trim() : '',
      ),
    );
  }

  void _updateUser(String uid, AdminUserEntry Function(AdminUserEntry) edit) {
    for (var i = 0; i < _users.length; i++) {
      if (_users[i].uid == uid) _users[i] = edit(_users[i]);
    }
    _changes.add(null);
  }

  @override
  Future<void> deleteDog(String dogId) async {
    _dogs.remove(dogId);
  }

  @override
  Future<void> deleteChatMessage(String chatId, String messageId) async {
    _messages.remove('$chatId/$messageId');
  }

  @override
  Stream<List<AdminContentItem>> watchContent(AdminContentKind kind) async* {
    yield List.of(_content[kind]!);
    yield* _changes.stream.map((_) => List.of(_content[kind]!));
  }

  @override
  Future<void> closeContent(AdminContentKind kind, String id) async {
    final status = switch (kind) {
      AdminContentKind.lostDog => 'resolved',
      AdminContentKind.adoption => 'adopted',
      AdminContentKind.group => 'approved',
      AdminContentKind.event => null,
    };
    if (status == null) return;
    final list = _content[kind]!;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item.id != id) continue;
      list[i] = AdminContentItem(
        kind: kind,
        id: id,
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        ownerId: item.ownerId,
        status: status,
        createdAt: item.createdAt,
      );
    }
    _changes.add(null);
  }

  @override
  Future<void> deleteContent(AdminContentKind kind, String id) async {
    _content[kind]!.removeWhere((item) => item.id == id);
    _changes.add(null);
  }

  @override
  Future<AppUpdateConfig?> fetchAppConfig() async => appConfig;

  @override
  Future<void> saveAppConfig(AppUpdateConfig config) async {
    appConfig = config;
  }

  List<FeedbackEntry> _sortedFeedback() {
    return List<FeedbackEntry>.from(_feedback)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<FeedbackEntry> _seedFeedback() {
    return [
      FeedbackEntry(
        id: 'feedback-1',
        userId: 'local-user',
        userName: 'Milica',
        userEmail: 'milica@example.com',
        category: AdminFeedback.categories[1],
        subject: 'Mapa se sporo učitava',
        message: 'Kada otvorim mapu na mobilnom podatku, pinovi kasne.',
        status: FeedbackEntry.statusNew,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FeedbackEntry(
        id: 'feedback-2',
        userId: 'seed-nikola',
        userName: 'Nikola',
        userEmail: 'nikola@example.com',
        category: AdminFeedback.categories.first,
        subject: 'Predlog za nove parkove',
        message: 'Dodajte Futoški park u listu lokacija za šetnje.',
        status: FeedbackEntry.statusResolved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<AdminUserEntry> _seedUsers() {
    return [
      AdminUserEntry(
        uid: 'local-user',
        name: 'Milica',
        email: 'milica@example.com',
        role: AdminRoles.user,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      AdminUserEntry(
        uid: 'seed-nikola',
        name: 'Nikola',
        email: 'nikola@example.com',
        role: AdminRoles.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
    ];
  }
}
