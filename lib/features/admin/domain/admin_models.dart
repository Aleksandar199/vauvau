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

class AdminUserEntry {
  const AdminUserEntry({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
}
