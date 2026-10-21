import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/utils/external_link_launcher.dart';
import '../data/app_update_repository.dart';
import '../domain/app_update.dart';
import 'app_update_strings.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreAppUpdateRepository(FirebaseFirestore.instance);
  }
  return LocalAppUpdateRepository();
});

/// Store of this device: Android → Play, iOS → App Store, web/desktop →
/// none (no prompt).
final appUpdatePlatformProvider = Provider<AppStorePlatform?>((ref) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => AppStorePlatform.android,
    TargetPlatform.iOS => AppStorePlatform.ios,
    _ => null,
  };
});

/// Test override for the installed build; null = ask the platform.
final appBuildNumberProvider = Provider<int?>((ref) => null);

/// Build number of the INSTALLED app = the `+N` from pubspec.yaml `version:`
/// (Flutter writes it into the APK/AAB as versionCode), read at runtime –
/// nothing to keep in sync by hand. Null when the platform cannot tell (then
/// no update prompt is shown). A hand-kept constant used before 2026-10-19
/// drifted from the real versionCode and the required dialog never closed.
final installedBuildNumberProvider = FutureProvider<int?>((ref) async {
  final override = ref.watch(appBuildNumberProvider);
  if (override != null) return override;
  try {
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber.trim());
    if (build != null && build > 0) return build;
  } catch (error) {
    debugPrint('installed build number unavailable: $error');
  }
  return null;
});

/// Update status for this build; upToDate while unknown.
final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>((ref) async {
  final ready = ref.watch(
    firestoreAuthReadyProvider.select((value) => value.value ?? false),
  );
  final platform = ref.watch(appUpdatePlatformProvider);
  if ((!ready && isFirebaseReady) ||
      platform == null ||
      platform.storeUris.isEmpty) {
    return AppUpdateStatus.upToDate;
  }
  final config = await ref.watch(appUpdateRepositoryProvider).fetch(platform);
  final build = await ref.watch(installedBuildNumberProvider.future);
  if (config == null || build == null) return AppUpdateStatus.upToDate;
  return config.statusFor(build);
});

/// Shows the update dialog once per app start when a newer build exists;
/// a required update cannot be dismissed. Android opens Play, iOS the App
/// Store (only once `kAppStoreId` is set) – never the other platform's store.
class AppUpdateHost extends ConsumerStatefulWidget {
  const AppUpdateHost({super.key, required this.child, this.enabled});

  final Widget child;

  /// Defaults to: this device has a store to open ([appUpdatePlatformProvider]).
  final bool? enabled;

  @override
  ConsumerState<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends ConsumerState<AppUpdateHost> {
  var _shown = false;

  bool get _enabled =>
      widget.enabled ??
      (ref.read(appUpdatePlatformProvider)?.storeUris.isNotEmpty ?? false);

  Future<void> _open() async {
    final launcher = ref.read(externalLinkLauncherProvider);
    final uris = ref.read(appUpdatePlatformProvider)?.storeUris ?? const [];
    for (final uri in uris) {
      try {
        if (await launcher.open(uri)) return;
      } catch (_) {}
    }
  }

  void _show(AppUpdateStatus status) {
    if (_shown || status == AppUpdateStatus.upToDate || !mounted) {
      return;
    }
    _shown = true;
    final required = status == AppUpdateStatus.required;
    final installed = ref.read(installedBuildNumberProvider).value;
    showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (dialogContext) => PopScope(
        canPop: !required,
        child: AlertDialog(
          title: Text(
            required ? AppUpdateStrings.requiredTitle : AppUpdateStrings.title,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                required
                    ? AppUpdateStrings.requiredBody
                    : AppUpdateStrings.body,
              ),
              if (installed != null) ...[
                const SizedBox(height: 12),
                Text(
                  AppUpdateStrings.installedBuild(installed),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            if (!required)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppUpdateStrings.later),
              ),
            FilledButton(
              key: const ValueKey('app-update-button'),
              onPressed: _open,
              child: Text(AppUpdateStrings.update),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled) {
      ref.listen<AsyncValue<AppUpdateStatus>>(appUpdateStatusProvider, (
        _,
        next,
      ) {
        final status = next.value;
        if (status != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(status));
        }
      });
    }
    return widget.child;
  }
}
