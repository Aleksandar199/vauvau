import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../moderation/presentation/moderation_strings.dart';
import '../../domain/map_place.dart';
import '../../domain/map_place_type.dart';
import '../../domain/models/poi_model.dart';
import '../map_strings.dart';

Future<void> showPlaceSheet({
  required BuildContext context,
  required MapPlace place,
  required double distanceKm,
  required VoidCallback onJoin,
  required VoidCallback onDirections,
  VoidCallback? onCall,
  required VoidCallback onReport,
  VoidCallback? onInappropriate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return PlacePreviewSheet(
        place: place,
        distanceKm: distanceKm,
        onJoin: onJoin,
        onDirections: onDirections,
        onCall: onCall,
        onReport: onReport,
        onInappropriate: onInappropriate,
      );
    },
  );
}

class PlacePreviewSheet extends StatefulWidget {
  const PlacePreviewSheet({
    super.key,
    required this.place,
    required this.distanceKm,
    required this.onJoin,
    required this.onDirections,
    this.onCall,
    required this.onReport,
    this.onInappropriate,
  });

  final MapPlace place;
  final double distanceKm;
  final VoidCallback onJoin;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onReport;
  final VoidCallback? onInappropriate;

  @override
  State<PlacePreviewSheet> createState() => _PlacePreviewSheetState();
}

class _PlacePreviewSheetState extends State<PlacePreviewSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (place.isEmergencyService ||
                    (place.is24_7 && place.type == MapPlaceType.vet))
                  const _Badge(
                    label: MapStrings.emergencyBadge,
                    background: Color(0xFFFEE2E2),
                    foreground: Color(0xFFB91C1C),
                  )
                else
                  _Badge(
                    label: _categoryBadge(place.type),
                    background: place.pinColor.withValues(alpha: 0.16),
                    foreground: const Color(0xFF1F2937),
                  ),
                _VerificationBadge(place: place),
                if (place.overnightStay)
                  const _Badge(
                    label: MapStrings.amenityOvernight,
                    background: Color(0xFFEEF2FF),
                    foreground: Color(0xFF312E81),
                  ),
                if (place.dayCare)
                  const _Badge(
                    label: MapStrings.amenityDayCare,
                    background: Color(0xFFFEF3C7),
                    foreground: Color(0xFF92400E),
                  ),
                if (place.hasYard)
                  const _Badge(
                    label: MapStrings.amenityYard,
                    background: Color(0xFFDCFCE7),
                    foreground: Color(0xFF166534),
                  ),
                if (place.pricePerNight != null)
                  _Badge(
                    label: MapStrings.pricePerNightLabel(place.pricePerNight!),
                    background: const Color(0xFFF3F4F6),
                    foreground: const Color(0xFF1F2937),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              MapStrings.addressAndDistance(place.address, widget.distanceKm),
              style: theme.textTheme.bodyMedium,
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              if (place.source.isNotEmpty)
                Text(
                  '${MapStrings.sourceLabel}: ${place.source}',
                  style: theme.textTheme.bodySmall,
                ),
              if (place.rating != null)
                Text(
                  MapStrings.ratingLabel(place.rating!),
                  style: theme.textTheme.titleMedium,
                ),
              if (place.nearbyDogs > 0) ...[
                const SizedBox(height: 4),
                Text(MapStrings.nearbyCount(place.nearbyDogs)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onJoin();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Text(MapStrings.join),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _expanded = true),
                    icon: const Icon(Icons.info_outline),
                    label: const Text(MapStrings.openProfile),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDirections();
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(MapStrings.navigation),
                  ),
                ),
              ],
            ),
            if (widget.onCall != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onCall!();
                  },
                  icon: const Icon(Icons.call),
                  label: const Text(MapStrings.callNow),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _confirmReport(context),
                child: const Text(MapStrings.reportChange),
              ),
            ),
            if (widget.onInappropriate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onInappropriate!();
                  },
                  child: const Text(ModerationStrings.reportAction),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(MapStrings.reportTitle),
          content: const Text(MapStrings.reportBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(MapStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(MapStrings.reportConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      widget.onReport();
    }
  }
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
    final color = place.pinColor;
    final size = selected ? 36.0 : 32.0;
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
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: selected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    place.type.icon,
                    color: AppColors.onPrimary,
                    size: selected ? 18 : 16,
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

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.place});

  final MapPlace place;

  @override
  Widget build(BuildContext context) {
    final verified =
        place.verificationStatus == PoiVerificationStatus.verified;
    final reported =
        place.verificationStatus == PoiVerificationStatus.reported;
    final submitted = place.verificationStatus.isAwaitingReview;
    final label = verified
        ? MapStrings.verifiedBadge
        : reported
            ? MapStrings.reportedBadge
            : submitted
                ? MapStrings.pendingBadge
                : MapStrings.unknownBadge;
    final date = place.lastVerified;
    return _Badge(
      label: verified && date != null
          ? '$label · ${MapStrings.lastVerifiedOn(date)}'
          : label,
      background: verified
          ? const Color(0xFFDCFCE7)
          : reported
              ? const Color(0xFFFEE2E2)
              : submitted
                  ? const Color(0xFFE0E7FF)
                  : const Color(0xFFF3F4F6),
      foreground: verified
          ? const Color(0xFF166534)
          : reported
              ? const Color(0xFF991B1B)
              : submitted
                  ? const Color(0xFF3730A3)
                  : const Color(0xFF4B5563),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _categoryBadge(MapPlaceType type) {
  return switch (type) {
    MapPlaceType.park => MapStrings.dogParkBadge,
    MapPlaceType.cafe => MapStrings.cafeFriendlyBadge,
    MapPlaceType.petShop => MapStrings.petShop,
    MapPlaceType.groomer => MapStrings.groomer,
    MapPlaceType.vet => MapStrings.vet,
    MapPlaceType.dogHotel => MapStrings.dogHotel,
    MapPlaceType.petSitter => MapStrings.petSitter,
  };
}
