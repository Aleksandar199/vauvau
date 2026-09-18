import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../../chat/presentation/widgets/dog_avatar.dart';
import '../../../discover/domain/discover_profile.dart';
import '../../domain/walking_dog_pin.dart';
import '../map_strings.dart';

Future<void> showWalkerSheet({
  required BuildContext context,
  required WalkingDogPin pin,
  required VoidCallback onOpenChat,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final profile = pin.profile;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MapStrings.walkingDogs,
              style: Theme.of(sheetContext).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            WalkerMiniCard(profile: profile, status: pin.status),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onOpenChat();
                },
                child: const Text(MapStrings.openChat),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class WalkerMiniCard extends StatelessWidget {
  const WalkerMiniCard({
    super.key,
    required this.profile,
    required this.status,
  });

  final DiscoverProfile profile;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MapStrings.viewCard,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DogAvatar(
                photoUrl: profile.photoUrls.isEmpty
                    ? ''
                    : profile.photoUrls.first,
                size: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.headline,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(profile.subtitle),
                    const SizedBox(height: 4),
                    Text(status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalkerPin extends StatelessWidget {
  const WalkerPin({
    super.key,
    required this.pin,
    required this.onTap,
    this.selected = false,
  });

  final WalkingDogPin pin;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final url = pin.profile.photoUrls.isEmpty ? '' : pin.profile.photoUrls.first;
    final size = selected ? 50.0 : 44.0;
    return Semantics(
      button: true,
      label: pin.profile.name,
      child: Tooltip(
        message: pin.profile.name,
        child: Material(
          key: Key('walker-${pin.profile.id}'),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: PulseBadge(
              color: AppColors.success,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.4),
                      blurRadius: selected ? 16 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: DogAvatar(photoUrl: url, size: size - 6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
