import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkLauncher {
  const ExternalLinkLauncher();

  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>((ref) {
  return const ExternalLinkLauncher();
});
