import 'package:firebase_core/firebase_core.dart';

bool get isFirebaseReady => Firebase.apps.isNotEmpty;
