import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_link_launcher.dart';
import '../../../moderation/presentation/moderation_strings.dart';
import '../../domain/map_place.dart';
import '../../domain/map_place_type.dart';
import '../../domain/models/poi_model.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../map_strings.dart';
import '../poi_report_controller.dart';
import '../user_poi_controller.dart';

Future<void> showPlaceSheet({
  required BuildContext context,
  required MapPlace place,
  required double distanceKm,
  required VoidCallback onJoin,
  required VoidCallback onDirections,
  VoidCallback? onCall,
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
        onInappropriate: onInappropriate,
      );
    },
  );
}

class PlacePreviewSheet extends ConsumerStatefulWidget {
  const PlacePreviewSheet({
    super.key,
    required this.place,
    required this.distanceKm,
    required this.onJoin,
    required this.onDirections,
    this.onCall,
    this.onInappropriate,
  });

  final MapPlace place;
  final double distanceKm;
  final VoidCallback onJoin;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onInappropriate;

  @override
  ConsumerState<PlacePreviewSheet> createState() => _PlacePreviewSheetState();
}

class _PlacePreviewSheetState extends ConsumerState<PlacePreviewSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: theme.textTheme.titleLarge),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (place.isEmergencyService ||
                        (place.is24_7 && place.type == MapPlaceType.vet))
                      _Badge(
                        label: MapStrings.emergencyBadge,
                        background: Color(0xFFB91C1C),
                        foreground: Colors.white,
                      )
                    else
                      _Badge(
                        label: _categoryBadge(place),
                        background: place.pinColor,
                        foreground: Colors.white,
                      ),
                    _VerificationBadge(place: place),
                    if (place.isSponsored)
                      _Badge(
                        label: place.sponsorBadge.isNotEmpty
                            ? place.sponsorBadge
                            : MapStrings.sponsoredBadge,
                        background: const Color(0xFF7C3AED),
                        foreground: Colors.white,
                      ),
                    if (place.petFriendly)
                      _Badge(
                        label: MapStrings.amenityDogFriendly,
                        background: Color(0xFFEEF2FF),
                        foreground: Color(0xFF312E81),
                      ),
                    if (place.dogFriendlyIndoor == true)
                      _Badge(
                        label: MapStrings.amenityIndoor,
                        background: Color(0xFFDCFCE7),
                        foreground: Color(0xFF166534),
                      ),
                    if (place.dogFriendlyOutdoor == true)
                      _Badge(
                        label: MapStrings.amenityOutdoor,
                        background: Color(0xFFDCFCE7),
                        foreground: Color(0xFF166534),
                      ),
                    if (place.waterAvailable == true)
                      _Badge(
                        label: MapStrings.amenityWater,
                        background: Color(0xFFE0F2FE),
                        foreground: Color(0xFF075985),
                      ),
                    if (place.overnightStay)
                      _Badge(
                        label: MapStrings.amenityOvernight,
                        background: Color(0xFFEEF2FF),
                        foreground: Color(0xFF312E81),
                      ),
                    if (place.dayCare)
                      _Badge(
                        label: MapStrings.amenityDayCare,
                        background: Color(0xFFFEF3C7),
                        foreground: Color(0xFF92400E),
                      ),
                    if (place.hasYard)
                      _Badge(
                        label: MapStrings.amenityYard,
                        background: Color(0xFFDCFCE7),
                        foreground: Color(0xFF166534),
                      ),
                    if (place.pricePerNight != null)
                      _Badge(
                        label:
                            MapStrings.pricePerNightLabel(place.pricePerNight!),
                        background: const Color(0xFFF3F4F6),
                        foreground: const Color(0xFF1F2937),
                      ),
                  ],
                ),
                if (place.municipality.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    place.municipality,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 12),
                Text(
                  MapStrings.addressAndDistance(
                    place.address,
                    widget.distanceKm,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                if (place.openingHours.trim().isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    '${MapStrings.hoursLabel}: ${place.openingHours.trim()}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (_expanded) ...[
                  SizedBox(height: 12),
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
                    SizedBox(height: 4),
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
                      label: Text(MapStrings.join),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _expanded = true),
                        icon: const Icon(Icons.info_outline),
                        label: Text(MapStrings.openProfile),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDirections();
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: Text(MapStrings.openNavigation),
                      ),
                    ),
                  ],
                ),
                if (place.website != null && place.website!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final raw = place.website!.trim();
                        final uri = Uri.tryParse(
                          raw.startsWith('http') ? raw : 'https://$raw',
                        );
                        if (uri != null) {
                          ExternalLinkLauncher().open(uri);
                        }
                      },
                      icon: const Icon(Icons.language),
                      label: Text(MapStrings.websiteAction),
                    ),
                  ),
                ],
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
                      label: Text(MapStrings.callNow),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _openReportChangeDialog(context),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            MapStrings.reportChange,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onInappropriate != null) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onInappropriate!();
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ModerationStrings.reportAction,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReportChangeDialog(BuildContext context) async {
    // Capture before nested sheets close — sheet context unmounts on pop.
    final messenger = ScaffoldMessenger.of(context);

    var confirmedVerified = false;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _ReportChangeSheet(
          place: widget.place,
          onSubmit: (changeType, description) async {
            final isConfirm =
                changeType == MapStrings.reportChangeConfirmVerified;
            confirmedVerified = isConfirm;
            await ref.read(poiReportsProvider.notifier).submitChangeRequest(
                  placeId: widget.place.id,
                  placeName: widget.place.name,
                  changeType: changeType,
                  description: description,
                  markAsReported: !isConfirm,
                );
            if (isConfirm) {
              ref
                  .read(poiConfirmationsProvider.notifier)
                  .confirm(widget.place.id);
              if (ref.read(isAdminProvider)) {
                try {
                  await ref
                      .read(userPoiSubmissionsProvider.notifier)
                      .approve(widget.place.id);
                } catch (error) {
                  debugPrint('Admin POI approve skipped: $error');
                }
              }
            }
          },
        );
      },
    );

    if (submitted != true) return;

    if (context.mounted) {
      Navigator.of(context).pop();
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            confirmedVerified
                ? MapStrings.reportConfirmThanks
                : MapStrings.reportThanks,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF166534),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
  }
}

class _ReportChangeSheet extends StatefulWidget {
  const _ReportChangeSheet({
    required this.place,
    required this.onSubmit,
  });

  final MapPlace place;
  final Future<void> Function(String changeType, String description) onSubmit;

  @override
  State<_ReportChangeSheet> createState() => _ReportChangeSheetState();
}

class _ReportChangeSheetState extends State<_ReportChangeSheet> {
  List<String> get _changeTypes => [
        MapStrings.reportChangeConfirmVerified,
        MapStrings.reportChangeWrongHours,
        MapStrings.reportChangeClosed,
        MapStrings.reportChangeWrongLocation,
        MapStrings.reportChangeOther,
      ];

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedType;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(MapStrings.reportTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  widget.place.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  MapStrings.reportBody,
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: MapStrings.reportChangeTypeLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in _changeTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() {
                            _selectedType = value;
                            _error = null;
                          }),
                  validator: (value) => value == null || value.isEmpty
                      ? MapStrings.reportChangeTypeRequired
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_submitting,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: MapStrings.reportChangeDescriptionLabel,
                    hintText: MapStrings.reportChangeDescriptionHint,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(MapStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(MapStrings.reportChangeSubmit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final changeType = _selectedType;
    if (changeType == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        changeType,
        _descriptionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('POI change report submit failed: $error');
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : MapStrings.reportChangeFailed;
      setState(() {
        _submitting = false;
        _error = message;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFB91C1C),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
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

String _categoryBadge(MapPlace place) {
  return switch (place.type) {
    MapPlaceType.park => place.isOfficialDogPark
        ? MapStrings.dogParkBadge
        : MapStrings.publicParkBadge,
    MapPlaceType.cafe => place.petFriendly
        ? MapStrings.cafeFriendlyBadge
        : MapStrings.cafePlainBadge,
    MapPlaceType.restaurant => place.petFriendly
        ? MapStrings.restaurantBadge
        : MapStrings.restaurantPlainBadge,
    MapPlaceType.petShop => MapStrings.petShop,
    MapPlaceType.groomer => MapStrings.groomer,
    MapPlaceType.vet => MapStrings.vet,
    MapPlaceType.lodging => MapStrings.lodging,
    MapPlaceType.training => MapStrings.training,
    MapPlaceType.dogHotel => MapStrings.dogHotel,
    MapPlaceType.selfWash => MapStrings.selfWash,
    MapPlaceType.dogTreats => MapStrings.dogTreats,
    MapPlaceType.shelter => MapStrings.shelter,
    MapPlaceType.water => MapStrings.waterForDogs,
    MapPlaceType.petSitter => MapStrings.petSitter,
    MapPlaceType.other => MapStrings.otherPlace,
  };
}
