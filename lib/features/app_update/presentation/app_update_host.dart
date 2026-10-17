import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Build number of the running app (overridable in tests).
final appBuildNumberProvider = Provider<int>((ref) => kAppBuildNumber);

/// Update status for this build; upToDate while unknown.
final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>((ref) async {
  final ready = ref.watch(
    firestoreAuthReadyProvider.select((value) => value.value ?? false),
  );
  if (!ready && isFirebaseReady) {
    return AppUpdateStatus.upToDate;
  }
  final config = await ref.watch(appUpdateRepositoryProvider).fetch();
  return config?.statusFor(ref.watch(appBuildNumberProvider)) ??
      AppUpdateStatus.upToDate;
});

/// Shows the update dialog once per app start when a newer build exists;
/// a required update cannot be dismissed. Android only (Play listing).
class AppUpdateHost extends ConsumerStatefulWidget {
  const AppUpdateHost({super.key, required this.child, this.enabled});

  final Widget child;

  /// Defaults to Android only.
  final bool? enabled;

  @override
  ConsumerState<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends ConsumerState<AppUpdateHost> {
  var _shown = false;

  bool get _enabled =>
      widget.enabled ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<void> _open() async {
    final launcher = ref.read(externalLinkLauncherProvider);
    var opened = false;
    try {
      opened = await launcher.open(Uri.parse(kPlayStoreMarketUrl));
    } catch (_) {}
    if (!opened) {
      try {
        await launcher.open(Uri.parse(kPlayStoreWebUrl));
      } catch (_) {}
    }
  }

  void _show(AppUpdateStatus status) {
    if (_shown || status == AppUpdateStatus.upToDate || !mounted) {
      return;
    }
    _shown = true;
    final required = status == AppUpdateStatus.required;
    showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (dialogContext) => PopScope(
        canPop: !required,
        child: AlertDialog(
          title: Text(
            required ? AppUpdateStrings.requiredTitle : AppUpdateStrings.title,
          ),
          content: Text(
            required ? AppUpdateStrings.requiredBody : AppUpdateStrings.body,
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
