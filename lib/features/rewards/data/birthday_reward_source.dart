import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../domain/birthday_reward.dart';

/// Birthday gift settings (`app_config/birthday`); disabled when the document
/// is missing, unreadable or there is no Firebase.
final birthdayRewardConfigProvider = FutureProvider<BirthdayRewardConfig>((
  ref,
) async {
  if (!isFirebaseReady) {
    return BirthdayRewardConfig.disabled;
  }
  try {
    final snap = await FirebaseFirestore.instance
        .doc(BirthdayRewardConfig.docPath)
        .get()
        .timeout(const Duration(seconds: 5));
    return BirthdayRewardConfig.fromMap(snap.data());
  } catch (error) {
    debugPrint('birthday reward config: $error');
    return BirthdayRewardConfig.disabled;
  }
});
