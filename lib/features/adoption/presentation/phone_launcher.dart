import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhoneLauncher {
  const PhoneLauncher();

  Future<bool> call(String phone) async {
    final compact = phone.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) {
      return false;
    }
    final first = compact.split(RegExp(r'[,/]')).first.trim();
    final uri = Uri(scheme: 'tel', path: first);
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri);
  }
}

final phoneLauncherProvider = Provider<PhoneLauncher>((ref) {
  return const PhoneLauncher();
});
