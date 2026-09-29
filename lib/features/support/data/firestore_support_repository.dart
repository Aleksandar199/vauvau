import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/admin_feedback.dart';
import '../domain/support_repository.dart';

class FirestoreSupportRepository implements SupportRepository {
  FirestoreSupportRepository({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Future<void> submitFeedback(AdminFeedback feedback) async {
    try {
      await firestore.collection('admin_feedback').add(<String, Object>{
        'userId': feedback.userId,
        'userName': feedback.userName,
        'userEmail': feedback.userEmail,
        'category': feedback.category,
        'subject': feedback.subject,
        'message': feedback.message,
        'createdAt': FieldValue.serverTimestamp(),
        'status': feedback.status,
      });
    } catch (error, stack) {
      debugPrint('Admin feedback FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }
}
