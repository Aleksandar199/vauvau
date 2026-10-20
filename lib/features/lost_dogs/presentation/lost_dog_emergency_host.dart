import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lost_dog_popup_store.dart';
import '../domain/lost_dog.dart';
import 'lost_dog_actions.dart';
import 'lost_dogs_controller.dart';

class LostDogEmergencyHost extends ConsumerStatefulWidget {
  const LostDogEmergencyHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LostDogEmergencyHost> createState() =>
      _LostDogEmergencyHostState();
}

class _LostDogEmergencyHostState extends ConsumerState<LostDogEmergencyHost> {
  var _checked = false;

  void _maybeShow(List<LostDog> dogs) {
    if (_checked || dogs.isEmpty || !mounted) {
      return;
    }
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (await LostDogPopupStore.hasDismissed()) {
        return;
      }
      if (!mounted) {
        return;
      }
      await showLostDogEmergencyDialog(
        context: context,
        ref: ref,
        dog: dogs.first,
      );
      await LostDogPopupStore.markDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only the user's own city (everyone when the user has no city).
    final recent = ref.watch(emergencyLostDogsProvider);
    _maybeShow(recent);
    ref.listen(emergencyLostDogsProvider, (previous, next) {
      _maybeShow(next);
    });
    return widget.child;
  }
}
