import 'package:flutter/widgets.dart';

/// Non-web stub — never used at runtime on mobile/desktop.
Widget buildFirebaseWebImage({
  required String url,
  required BoxFit fit,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  throw UnsupportedError('Firebase web image is only available on web.');
}
