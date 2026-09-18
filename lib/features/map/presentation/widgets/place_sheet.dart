import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/map_place.dart';
import '../../domain/map_place_type.dart';
import '../map_strings.dart';

Future<void> showPlaceSheet({
  required BuildContext context,
  required MapPlace place,
  required VoidCallback onJoin,
  required VoidCallback onDirections,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final isPark = place.type == MapPlaceType.park;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(isPark ? MapStrings.park : MapStrings.cafe),
            const SizedBox(height: 8),
            Text(place.neighborhood),
            const SizedBox(height: 12),
            Text(MapStrings.nearbyCount(place.nearbyDogs)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onJoin();
                    },
                    child: const Text(MapStrings.join),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onDirections();
                    },
                    child: const Text(MapStrings.directions),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class PlacePin extends StatelessWidget {
  const PlacePin({
    super.key,
    required this.place,
    required this.onTap,
    this.selected = false,
  });

  final MapPlace place;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isPark = place.type == MapPlaceType.park;
    final color = isPark ? AppColors.success : AppColors.cafe;
    final size = selected ? 48.0 : 42.0;
    return Semantics(
      button: true,
      label: place.name,
      child: Tooltip(
        message: place.name,
        child: Material(
          key: Key('place-${place.id}'),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: selected ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPark ? Icons.park : Icons.local_cafe,
                    color: AppColors.onPrimary,
                    size: selected ? 24 : 20,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
