import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  const MapsLauncher();

  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final destination = '$latitude,$longitude';
    final query = label == null || label.isEmpty
        ? destination
        : Uri.encodeComponent('$label ($destination)');
    final google = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=walking',
    );
    if (await canLaunchUrl(google)) {
      return launchUrl(google, mode: LaunchMode.externalApplication);
    }
    final apple = Uri.parse('http://maps.apple.com/?daddr=$destination');
    if (await canLaunchUrl(apple)) {
      return launchUrl(apple, mode: LaunchMode.externalApplication);
    }
    final geo = Uri.parse('geo:$destination?q=$query');
    if (await canLaunchUrl(geo)) {
      return launchUrl(geo, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

final mapsLauncherProvider = Provider<MapsLauncher>((ref) {
  return const MapsLauncher();
});
