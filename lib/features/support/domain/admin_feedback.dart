class AdminFeedback {
  const AdminFeedback({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.subject,
    required this.message,
    this.status = statusNew,
  });

  static const String statusNew = 'new';

  static const List<String> categories = [
    '💡 Predlog',
    '🐛 Prijava problema',
    '❤️ Pohvala',
    '❓ Pitanje',
  ];

  final String userId;
  final String userName;
  final String userEmail;
  final String category;
  final String subject;
  final String message;
  final String status;
}
