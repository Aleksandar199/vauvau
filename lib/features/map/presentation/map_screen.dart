import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo.dart';
import '../../../core/theme/app_colors.dart';
import '../../adoption/presentation/phone_launcher.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/presentation/widgets/scheduled_walks_banner.dart';
import '../../home/presentation/home_tab.dart';
import '../../discover/presentation/widgets/discover_filter_chip.dart';
import '../../location/domain/location_access.dart';
import '../../location/presentation/location_controller.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../notifications/presentation/push_controller.dart';
import '../data/mock_map_data.dart';
import '../domain/map_city.dart';
import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/walk_session.dart';
import '../domain/walking_dog_pin.dart';
import 'map_strings.dart';
import 'maps_launcher.dart';
import 'poi_report_controller.dart';
import 'walk_controller.dart';
import 'widgets/add_poi_sheet.dart';
import 'widgets/mock_map_canvas.dart';
import 'widgets/place_sheet.dart';
import 'widgets/walker_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _search = TextEditingController();
  MapLayerFilter _filter = MapLayerFilter.all;
  final Set<HotelAmenityFilter> _hotelAmenities = {};
  MapCityFocus _cityFocus = MapCityFocus.noviSad;
  String? _selectedId;

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walk = ref.watch(walkControllerProvider);
    final scheduledWalks = ref.watch(scheduledWalksProvider);
    final location = ref.watch(userLocationProvider);
    final places = _visiblePlaces(ref.watch(mapPlacesProvider));
    final walkers = _visibleWalkers(ref.watch(walkingDogsProvider));

    return Stack(
      children: [
        Positioned.fill(
          child: VauInteractiveMap(
            controller: _mapController,
            placeMarkers: [
              for (final place in places)
                Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: 44,
                  height: 52,
                  alignment: Alignment.bottomCenter,
                  child: PlacePin(
                    place: place,
                    selected: _selectedId == place.id,
                    onTap: () => _selectPlace(place),
                  ),
                ),
            ],
            overlayMarkers: [
              Marker(
                point: LatLng(location.latitude, location.longitude),
                width: 28,
                height: 28,
                child: const _UserDot(),
              ),
              for (final walker in walkers)
                Marker(
                  point: LatLng(walker.latitude, walker.longitude),
                  width: 108,
                  height: 78,
                  child: WalkerPin(
                    pin: walker,
                    selected: _selectedId == walker.profile.id,
                    onTap: () => _selectWalker(walker),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFF2A2A38),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: const Color(0xFFF8FAFC),
                        decoration: InputDecoration(
                          hintText: MapStrings.searchHint,
                          hintStyle: TextStyle(
                            color: const Color(0xFFF8FAFC).withValues(alpha: 0.72),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A38),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: const Color(0xFFF8FAFC).withValues(alpha: 0.28),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFF8FAFC),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (location.isFallback) ...[
                    const SizedBox(width: 8),
                    _LocationAlertButton(onPressed: _goToMyLocation),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CityPill(
                        label: MapStrings.cityNoviSad,
                        selected: _cityFocus == MapCityFocus.noviSad,
                        onTap: () => _selectCity(MapCityFocus.noviSad),
                      ),
                      const SizedBox(width: 8),
                      _CityPill(
                        label: MapStrings.cityBelgrade,
                        selected: _cityFocus == MapCityFocus.belgrade,
                        onTap: () => _selectCity(MapCityFocus.belgrade),
                      ),
                      const SizedBox(width: 8),
                      _CityPill(
                        label: MapStrings.cityMyLocation,
                        selected: _cityFocus == MapCityFocus.myLocation,
                        onTap: () => _selectCity(MapCityFocus.myLocation),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _filter == MapLayerFilter.hotels ? 88 : 40,
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final filter in MapLayerFilterX.primary)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: DiscoverFilterChip(
                                  label: filter.label,
                                  selected: _filter == filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                              ),
                            DiscoverFilterChip(
                              label: MapStrings.filterMore,
                              selected: _filter.isExtraPlaceFilter,
                              onTap: _openMoreFilters,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_filter == MapLayerFilter.hotels) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final amenity in HotelAmenityFilter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: DiscoverFilterChip(
                                    label: amenity.label,
                                    selected: _hotelAmenities.contains(amenity),
                                    onTap: () {
                                      setState(() {
                                        if (_hotelAmenities.contains(amenity)) {
                                          _hotelAmenities.remove(amenity);
                                        } else {
                                          _hotelAmenities.add(amenity);
                                        }
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (walk.isActive) ...[
                const SizedBox(height: 8),
                _WalkBanner(walk: walk),
              ],
              if (scheduledWalks.isNotEmpty) ...[
                const SizedBox(height: 8),
                ScheduledWalksBanner(walks: scheduledWalks),
              ],
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 88,
          child: Column(
            children: [
              _MapFab(
                tooltip: MapStrings.zoomIn,
                icon: Icons.add,
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 8),
              _MapFab(
                tooltip: MapStrings.zoomOut,
                icon: Icons.remove,
                onPressed: () => _zoomBy(-1),
              ),
              const SizedBox(height: 8),
              _MapFab(
                tooltip: MapStrings.myLocation,
                icon: Icons.my_location,
                onPressed: () => _goToMyLocation(),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 72,
          bottom: 16,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(28),
            child: walk.isActive
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                    ),
                    onPressed: () =>
                        ref.read(walkControllerProvider.notifier).end(),
                    icon: const Icon(Icons.stop),
                    label: const Text(MapStrings.endWalk),
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => _startWalkFlow(context),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text(MapStrings.startWalk),
                  ),
          ),
        ),
      ],
    );
  }

  List<MapPlace> _visiblePlaces(List<MapPlace> source) {
    if (!_filter.showsPlaces) {
      return const [];
    }
    final query = _search.text.trim().toLowerCase();
    final type = _filter.placeType;
    return source.where((place) {
      final matchesQuery = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.neighborhood.toLowerCase().contains(query);
      if (!matchesQuery) {
        return false;
      }
      if (_cityFocus == MapCityFocus.noviSad &&
          place.city != MapCity.noviSad) {
        return false;
      }
      if (_cityFocus == MapCityFocus.belgrade &&
          place.city != MapCity.belgrade) {
        return false;
      }
      if (_filter == MapLayerFilter.emergency) {
        return place.is24_7 || place.isEmergencyService;
      }
      if (type != null && place.type != type) {
        return false;
      }
      if (_filter == MapLayerFilter.hotels &&
          !_matchesHotelAmenities(place)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<WalkingDogPin> _visibleWalkers(List<WalkingDogPin> source) {
    if (_cityFocus == MapCityFocus.belgrade) {
      return const [];
    }
    if (!_filter.showsWalkers) {
      return const [];
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }
    return source
        .where(
          (pin) =>
              pin.profile.name.toLowerCase().contains(query) ||
              pin.status.toLowerCase().contains(query),
        )
        .toList();
  }

  bool _matchesHotelAmenities(MapPlace place) {
    if (_hotelAmenities.isEmpty) {
      return true;
    }
    if (_hotelAmenities.contains(HotelAmenityFilter.overnight) &&
        !place.overnightStay) {
      return false;
    }
    if (_hotelAmenities.contains(HotelAmenityFilter.dayCare) &&
        !place.dayCare) {
      return false;
    }
    if (_hotelAmenities.contains(HotelAmenityFilter.yard) && !place.hasYard) {
      return false;
    }
    if (_hotelAmenities.contains(HotelAmenityFilter.allDay) && !place.is24_7) {
      return false;
    }
    return true;
  }

  Future<void> _selectCity(MapCityFocus focus) async {
    setState(() => _cityFocus = focus);
    if (focus == MapCityFocus.myLocation) {
      await _goToMyLocation();
      return;
    }
    final target = focus == MapCityFocus.belgrade
        ? MapCityCameras.belgrade
        : MapCityCameras.noviSad;
    await _flyTo(target, MapCityCameras.cityZoom);
  }

  Future<void> _flyTo(LatLng dest, double zoom) async {
    try {
      final camera = _mapController.camera;
      final from = camera.center;
      final fromZoom = camera.zoom;
      const steps = 12;
      for (var i = 1; i <= steps; i++) {
        final t = Curves.easeInOut.transform(i / steps);
        _mapController.move(
          LatLng(
            from.latitude + (dest.latitude - from.latitude) * t,
            from.longitude + (dest.longitude - from.longitude) * t,
          ),
          fromZoom + (zoom - fromZoom) * t,
        );
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    } catch (_) {
      try {
        _mapController.move(dest, zoom);
      } catch (_) {}
    }
  }

  Future<void> _openMoreFilters() async {
    const addPlaceToken = Object();
    final selected = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MapStrings.filterMore,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text(MapStrings.addPlace),
                  onTap: () => Navigator.of(sheetContext).pop(addPlaceToken),
                ),
                const Divider(),
                for (final filter in MapLayerFilterX.extra)
                  ListTile(
                    leading: Icon(filter.placeType?.icon ?? Icons.place),
                    title: Text(filter.label),
                    selected: _filter == filter,
                    onTap: () => Navigator.of(sheetContext).pop(filter),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (identical(selected, addPlaceToken)) {
      await showAddPoiSheet(
        context,
        ref,
        initialCity: switch (_cityFocus) {
          MapCityFocus.belgrade => MapCity.belgrade,
          MapCityFocus.myLocation => MapCity.other,
          MapCityFocus.noviSad => MapCity.noviSad,
        },
      );
      return;
    }
    if (selected is MapLayerFilter) {
      setState(() => _filter = selected);
    }
  }

  void _zoomBy(double delta) {
    try {
      final camera = _mapController.camera;
      _mapController.move(
        camera.center,
        (camera.zoom + delta).clamp(10, 18).toDouble(),
      );
    } catch (_) {}
  }

  Future<void> _goToMyLocation() async {
    final access =
        await ref.read(userLocationProvider.notifier).requestPermission();
    if (!mounted) {
      return;
    }
    if (!access.canTrack && access != LocationAccess.unavailable) {
      await _showLocationDialog(access);
    }
    final location = ref.read(userLocationProvider);
    try {
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        limanZoom,
      );
    } catch (_) {}
  }

  Future<void> _startWalkFlow(BuildContext context, {String? preset}) async {
    final current = ref.read(userLocationProvider).access;
    if (current == LocationAccess.denied ||
        current == LocationAccess.permanentlyDenied ||
        current == LocationAccess.servicesDisabled) {
      final access =
          await ref.read(userLocationProvider.notifier).requestPermission();
      if (!context.mounted) {
        return;
      }
      if (!access.canTrack && access != LocationAccess.unavailable) {
        await _showLocationDialog(access);
        if (!context.mounted) {
          return;
        }
      }
    }
    await _promptStartWalk(context, preset: preset);
  }

  Future<void> _showLocationDialog(LocationAccess access) async {
    final title = switch (access) {
      LocationAccess.permanentlyDenied => MapStrings.locationPermanentTitle,
      LocationAccess.servicesDisabled => MapStrings.locationDisabledTitle,
      _ => MapStrings.locationDeniedTitle,
    };
    final body = switch (access) {
      LocationAccess.permanentlyDenied => MapStrings.locationPermanentBody,
      LocationAccess.servicesDisabled => MapStrings.locationDisabledBody,
      _ => MapStrings.locationDeniedBody,
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(MapStrings.useDefaultCity),
            ),
            if (access == LocationAccess.permanentlyDenied)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(locationClientProvider).openAppSettings();
                },
                child: const Text(MapStrings.openSettings),
              )
            else if (access == LocationAccess.denied)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(userLocationProvider.notifier).requestPermission();
                },
                child: const Text(MapStrings.allowLocation),
              ),
          ],
        );
      },
    );
  }

  Future<void> _selectPlace(MapPlace place) async {
    setState(() => _selectedId = place.id);
    try {
      _mapController.move(LatLng(place.latitude, place.longitude), 16);
    } catch (_) {}
    await showPlaceSheet(
      context: context,
      place: place,
      distanceKm: haversineKm(
        ref.read(userLocationProvider).coord,
        GeoCoord(place.latitude, place.longitude),
      ),
      onJoin: () => _startWalkFlow(
        context,
        preset: '${MapStrings.joinWalkStatusPrefix} ${place.name}',
      ),
      onDirections: () => _openDirections(place),
      onCall: place.phone.isEmpty ? null : () => _callPlace(place),
      onReport: () {
        ref.read(poiReportsProvider.notifier).report(place.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(MapStrings.reportThanks)),
        );
      },
      onInappropriate: () {
        showContentReportSheet(
          context: context,
          ref: ref,
          contentType: ReportContentType.poi,
          targetId: place.id,
        );
      },
    );
  }

  Future<void> _callPlace(MapPlace place) async {
    final opened = await ref.read(phoneLauncherProvider).call(place.phone);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(MapStrings.callFailed)),
      );
    }
  }

  Future<void> _openDirections(MapPlace place) async {
    final opened = await ref.read(mapsLauncherProvider).openDirections(
          latitude: place.latitude,
          longitude: place.longitude,
          label: place.name,
        );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(MapStrings.navigationFailed)),
      );
    }
  }

  Future<void> _selectWalker(WalkingDogPin pin) async {
    setState(() => _selectedId = pin.profile.id);
    try {
      _mapController.move(LatLng(pin.latitude, pin.longitude), 16);
    } catch (_) {}
    await showWalkerSheet(
      context: context,
      pin: pin,
      onJoinWalk: () {
        ref.read(pushControllerProvider.notifier).notifyWalk(
              dogName: pin.profile.name,
              ownerName: pin.profile.ownerName,
              dogId: pin.profile.id,
              peerUserId: pin.profile.ownerId,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(MapStrings.walkRequestSent)),
        );
        _openWalkerChat(pin);
      },
      onOpenChat: () => _openWalkerChat(pin),
    );
  }

  void _openWalkerChat(WalkingDogPin pin) {
    final chatId =
        ref.read(chatInboxProvider.notifier).openFromMatch(pin.profile);
    ref.read(homeTabIndexProvider.notifier).showMessages();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: chatId),
      ),
    );
  }

  Future<void> _promptStartWalk(BuildContext context, {String? preset}) async {
    final controller = TextEditingController(text: preset ?? '');
    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(MapStrings.startWalk),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: MapStrings.statusLabel,
                  hintText: MapStrings.statusHint,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text(MapStrings.statusWalking),
                    onPressed: () => controller.text = MapStrings.statusWalking,
                  ),
                  ActionChip(
                    label: const Text(MapStrings.statusResting),
                    onPressed: () => controller.text = MapStrings.statusResting,
                  ),
                  ActionChip(
                    label: const Text(MapStrings.statusLookingForPlay),
                    onPressed: () =>
                        controller.text = MapStrings.statusLookingForPlay,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(MapStrings.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text(MapStrings.confirm),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (status == null) {
      return;
    }
    ref.read(walkControllerProvider.notifier).start(
          statusMessage: status.isEmpty ? null : status,
        );
  }
}

class _CityPill extends StatelessWidget {
  const _CityPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2A2A38) : Colors.white,
      elevation: selected ? 3 : 1,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFFF8FAFC) : const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _WalkBanner extends StatelessWidget {
  const _WalkBanner({required this.walk});

  final WalkSession walk;

  @override
  Widget build(BuildContext context) {
    final message = walk.statusMessage;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF052E16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const _PulseDot(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MapStrings.walking,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    MapStrings.remaining(walk.remainingMinutes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFBBF7D0),
                        ),
                  ),
                  if (message != null && message.isNotEmpty)
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LocationAlertButton extends StatefulWidget {
  const _LocationAlertButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_LocationAlertButton> createState() => _LocationAlertButtonState();
}

class _LocationAlertButtonState extends State<_LocationAlertButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Material(
        color: const Color(0xFF2A2A38),
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(
          tooltip: MapStrings.allowLocation,
          onPressed: widget.onPressed,
          icon: const Icon(Icons.location_searching, color: Color(0xFFF8FAFC)),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return const _PulsingUserDot();
  }
}

class _PulsingUserDot extends StatefulWidget {
  const _PulsingUserDot();

  @override
  State<_PulsingUserDot> createState() => _PulsingUserDotState();
}

class _PulsingUserDotState extends State<_PulsingUserDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.35 + (_controller.value * 0.45);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.22 * (1 - pulse + 0.35)),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
