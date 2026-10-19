class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  static const String statusNew = 'new';
  static const String statusResolved = 'resolved';

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String category;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  bool get isResolved => status == statusResolved;

  FeedbackEntry copyWith({String? status}) {
    return FeedbackEntry(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      category: category,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

/// Role values stored in `users/{uid}.role`.
abstract final class AdminRoles {
  static const user = 'user';
  static const admin = 'admin';
  static const partner = 'partner';
}

class AdminUserEntry {
  const AdminUserEntry({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.photoUrl = '',
    this.city = '',
    this.partnerId = '',
    this.isSuspended = false,
    this.suspendedReason = '',
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final String photoUrl;
  final String city;
  final String partnerId;
  final bool isSuspended;
  final String suspendedReason;

  bool get isAdmin => role == AdminRoles.admin;

  bool get isPartner => role == AdminRoles.partner;

  AdminUserEntry copyWith({
    String? role,
    String? partnerId,
    bool? isSuspended,
    String? suspendedReason,
  }) {
    return AdminUserEntry(
      uid: uid,
      name: name,
      email: email,
      role: role ?? this.role,
      createdAt: createdAt,
      photoUrl: photoUrl,
      city: city,
      partnerId: partnerId ?? this.partnerId,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedReason: suspendedReason ?? this.suspendedReason,
    );
  }

  /// Name, email or uid contains [query] (case-insensitive).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        email.toLowerCase().contains(q) ||
        uid.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q);
  }
}

/// Public profile summary shown wherever the admin sees a user id.
class AdminUserRef {
  const AdminUserRef({
    required this.uid,
    required this.name,
    this.photoUrl = '',
    this.role = AdminRoles.user,
    this.exists = true,
  });

  /// `users/{uid}` is missing (deleted account) or unreadable.
  const AdminUserRef.unknown(this.uid)
      : name = '',
        photoUrl = '',
        role = AdminRoles.user,
        exists = false;

  final String uid;
  final String name;
  final String photoUrl;
  final String role;
  final bool exists;
}

class AdminDogRef {
  const AdminDogRef({
    required this.id,
    required this.name,
    this.breed = '',
    this.photoUrl = '',
    this.ownerId = '',
    this.exists = true,
  });

  const AdminDogRef.unknown(this.id)
      : name = '',
        breed = '',
        photoUrl = '',
        ownerId = '',
        exists = false;

  final String id;
  final String name;
  final String breed;
  final String photoUrl;
  final String ownerId;
  final bool exists;
}

class AdminMomentRef {
  const AdminMomentRef({
    required this.id,
    required this.caption,
    this.photoUrl = '',
    this.authorUserId = '',
    this.dogName = '',
    this.exists = true,
  });

  const AdminMomentRef.unknown(this.id)
      : caption = '',
        photoUrl = '',
        authorUserId = '',
        dogName = '',
        exists = false;

  final String id;
  final String caption;
  final String photoUrl;
  final String authorUserId;
  final String dogName;
  final bool exists;
}

/// A reported 1:1 chat message (`chats/{chatId}/messages/{id}`).
class AdminMessageRef {
  const AdminMessageRef({
    required this.chatId,
    required this.id,
    required this.text,
    this.senderId = '',
    this.imageUrl = '',
    this.exists = true,
  });

  const AdminMessageRef.unknown(this.chatId, this.id)
      : text = '',
        senderId = '',
        imageUrl = '',
        exists = false;

  final String chatId;
  final String id;
  final String text;
  final String senderId;
  final String imageUrl;
  final bool exists;
}

/// Dashboard numbers from `count()` / `sum()` aggregation queries. A null
/// value = the query failed (offline, rules or index not deployed).
class AdminStats {
  const AdminStats({
    this.users,
    this.newUsers7,
    this.newUsers30,
    this.dogs,
    this.matches,
    this.activeChats7,
    this.activeStories,
    this.moments,
    this.lostDogsActive,
    this.adoptionsAvailable,
    this.eventsUpcoming,
    this.groupsPending,
    this.walks,
    this.walkKm,
    this.couponsClaimed,
    this.couponsRedeemed,
    this.partners,
    this.suspendedUsers,
  });

  final int? users;
  final int? newUsers7;
  final int? newUsers30;
  final int? dogs;
  final int? matches;
  final int? activeChats7;
  final int? activeStories;
  final int? moments;
  final int? lostDogsActive;
  final int? adoptionsAvailable;
  final int? eventsUpcoming;
  final int? groupsPending;

  /// Rewarded walks (ledger entries of type `walk`).
  final int? walks;
  final int? walkKm;

  /// Unused (status `claimed`) and used coupons.
  final int? couponsClaimed;
  final int? couponsRedeemed;
  final int? partners;
  final int? suspendedUsers;
}

/// Admin-managed listings (lost dogs, adoption, events, groups).
enum AdminContentKind { lostDog, adoption, event, group }

class AdminContentItem {
  const AdminContentItem({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.ownerId = '',
    this.status = '',
    this.createdAt,
  });

  final AdminContentKind kind;
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String ownerId;

  /// lost dog: active/resolved, adoption: available/adopted, group:
  /// approved/pending, event: upcoming/past.
  final String status;
  final DateTime? createdAt;
}
