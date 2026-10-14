import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo.dart';
import '../../../core/theme/app_colors.dart';
import '../../adoption/presentation/phone_launcher.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../home/presentation/home_tab.dart';
import '../../discover/presentation/widgets/discover_filter_chip.dart';
import '../../location/domain/location_access.dart';
import '../../location/presentation/location_controller.dart';
import '../../location/presentation/home_city_provider.dart';
import '../../location/presentation/location_disclosure.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../notifications/presentation/push_controller.dart';
import '../data/mock_map_data.dart';
import '../domain/city_model.dart';
import '../domain/map_city.dart';
import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/walking_dog_pin.dart';
import 'add_place_screen.dart';
import 'cities_controller.dart';
import 'map_strings.dart';
import 'maps_launcher.dart';
import 'walk_controller.dart';
import 'widgets/add_poi_sheet.dart';
import 'widgets/city_picker_sheet.dart';
import 'widgets/mock_map_canvas.dart';
import 'widgets/place_sheet.dart';
import 'widgets/walk_history_sheet.dart';
import 'widgets/walk_stats_panel.dart';
import 'widgets/walker_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static final Set<String> _quickCityIds = {
    SeedCities.noviSad.id,
    SeedCities.belgrade.id,
    SeedCities.nis.id,
    SeedCities.kragujevac.id,
  };

  final MapController _mapController = MapController();
  final TextEditingController _search = TextEditingController();
  final Set<MapLayerFilter> _filters = {MapLayerFilter.all};
  final Set<HotelAmenityFilter> _hotelAmenities = {};
  String? _selectedId;
  bool _showList = false;
  ProviderSubscription<MapRegionSelection>? _regionSub;

  bool get _hotelsSelected =>
      _filters.contains(MapLayerFilter.hotels) ||
      _filters.contains(MapLayerFilter.lodging);

  void _toggleFilter(MapLayerFilter filter) {
    setState(() {
      if (filter == MapLayerFilter.all) {
        _filters
          ..clear()
          ..add(MapLayerFilter.all);
        return;
      }
      _filters.remove(MapLayerFilter.all);
      if (!_filters.add(filter)) {
        _filters.remove(filter);
      }
      if (_filters.isEmpty) {
        _filters.add(MapLayerFilter.all);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _regionSub = ref.listenManual<MapRegionSelection>(
      mapRegionProvider,
      (previous, next) {
        if (previous == next) return;
        _applyRegionCamera(next);
      },
    );
  }

  @override
  void dispose() {
    _regionSub?.close();
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walkActive = ref.watch(
      walkControllerProvider.select((session) => session.isActive),
    );
    final walkPaused = ref.watch(
      walkControllerProvider.select((session) => session.isPaused),
    );
    final walkPath = ref.watch(
      walkControllerProvider.select((session) => session.path),
    );
    final userCoord = ref.watch(
      userLocationProvider.select((location) => location.coord),
    );
    final locationFallback = ref.watch(
      userLocationProvider.select((location) => location.isFallback),
    );
    final region = ref.watch(mapRegionProvider);
    final places = _visiblePlaces(ref.watch(mapPlacesProvider), region);
    final walkers = _visibleWalkers(ref.watch(walkingDogsProvider), region);

    final walkRoute = [
      for (final point in walkPath) LatLng(point.latitude, point.longitude),
    ];
    final walkStart = walkPath.isNotEmpty ? walkPath.first : null;

    return Stack(
      children: [
        Positioned.fill(
          child: VauInteractiveMap(
            controller: _mapController,
            initialCenter: region.isMyLocation
                ? null
                : () {
                    final center = mapRegionCenter(region, userCoord);
                    return LatLng(center.latitude, center.longitude);
                  }(),
            initialZoom: region.isMyLocation ? null : region.zoom,
            routePoints: walkActive ? walkRoute : const [],
            routeColor: Theme.of(context).colorScheme.primary,
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
              if (walkActive && walkStart != null)
                Marker(
                  point: LatLng(walkStart.latitude, walkStart.longitude),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const _WalkStartMarker(),
                ),
              Marker(
                point: LatLng(userCoord.latitude, userCoord.longitude),
                width: walkActive ? 36 : 28,
                height: walkActive ? 36 : 28,
                alignment: Alignment.center,
                child: walkActive
                    ? const _WalkCurrentMarker()
                    : const _UserDot(),
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
                  if (locationFallback) ...[
                    const SizedBox(width: 8),
                    _LocationAlertButton(onPressed: _goToMyLocation),
                  ],
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    DiscoverFilterChip(
                      label: MapStrings.cityNoviSad,
                      selected: region.cityId == SeedCities.noviSad.id,
                      onTap: () => _selectQuickCity(SeedCities.noviSad),
                    ),
                    SizedBox(width: 8),
                    DiscoverFilterChip(
                      label: MapStrings.cityBelgrade,
                      selected: region.cityId == SeedCities.belgrade.id,
                      onTap: () => _selectQuickCity(SeedCities.belgrade),
                    ),
                    SizedBox(width: 8),
                    DiscoverFilterChip(
                      label: MapStrings.cityNis,
                      selected: region.cityId == SeedCities.nis.id,
                      onTap: () => _selectQuickCity(SeedCities.nis),
                    ),
                    SizedBox(width: 8),
                    DiscoverFilterChip(
                      label: MapStrings.cityKragujevac,
                      selected: region.cityId == SeedCities.kragujevac.id,
                      onTap: () => _selectQuickCity(SeedCities.kragujevac),
                    ),
                    SizedBox(width: 8),
                    _CityPickerButton(
                      label: region.isMyLocation ||
                              _quickCityIds.contains(region.cityId)
                          ? MapStrings.chooseCity
                          : region.label,
                      selected: region.isMyLocation ||
                          (region.cityId != null &&
                              !_quickCityIds.contains(region.cityId)),
                      onTap: () =>
                          showCityPickerSheet(context: context, ref: ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _hotelsSelected ? 88 : 40,
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
                                  selected: _filters.contains(filter),
                                  onTap: () => _toggleFilter(filter),
                                ),
                              ),
                            DiscoverFilterChip(
                              label: MapStrings.filterMore,
                              selected: _filters.any((f) => f.isExtraPlaceFilter),
                              onTap: _openMoreFilters,
                            ),
                            SizedBox(width: 8),
                            _MapViewModeChip(
                              label: _showList
                                  ? MapStrings.showMap
                                  : MapStrings.showList,
                              selected: _showList,
                              onTap: () =>
                                  setState(() => _showList = !_showList),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hotelsSelected) ...[
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
              if (places.isEmpty &&
                  !_filters.contains(MapLayerFilter.walkers)) ...[
                const SizedBox(height: 8),
                Material(
                  color: const Color(0xFF2A2A38),
                  borderRadius: BorderRadius.circular(14),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MapStrings.emptyCategoryTitle,
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          MapStrings.emptyCategoryBody,
                          style: TextStyle(color: Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (walkActive) ...[
                const SizedBox(height: 8),
                WalkGpsBanner(isPaused: walkPaused),
              ],
            ],
          ),
        ),
        if (_showList)
          Positioned(
            left: 12,
            right: 12,
            top: 210,
            bottom: walkActive ? 220 : 88,
            child: _PlacesListPanel(
              places: places,
              userCoord: userCoord,
              onOpen: _selectPlace,
              onDirections: _openDirections,
            ),
          ),
        Positioned(
          right: 12,
          bottom: walkActive ? 220 : 88,
          child: Column(
            children: [
              _MapFab(
                tooltip: MapStrings.zoomIn,
                icon: Icons.add,
                onPressed: () => _zoomBy(1),
              ),
              SizedBox(height: 8),
              _MapFab(
                tooltip: MapStrings.zoomOut,
                icon: Icons.remove,
                onPressed: () => _zoomBy(-1),
              ),
              SizedBox(height: 8),
              _MapFab(
                tooltip: MapStrings.myLocation,
                icon: Icons.my_location,
                onPressed: () => _goToMyLocation(),
              ),
            ],
          ),
        ),
        if (walkActive)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WalkStatsPanel(),
          )
        else
          Positioned(
            left: 16,
            right: 72,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 8,
                    shadowColor: Colors.black38,
                    borderRadius: BorderRadius.circular(28),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _startWalkFlow(context),
                      icon: const Icon(Icons.directions_walk),
                      label: Text(MapStrings.startWalk),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: IconButton(
                    tooltip: MapStrings.walkHistory,
                    onPressed: () => showWalkHistorySheet(context),
                    icon: const Icon(Icons.history),
                    iconSize: 26,
                    constraints: const BoxConstraints(
                      minWidth: 54,
                      minHeight: 54,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<MapPlace> _visiblePlaces(
    List<MapPlace> source,
    MapRegionSelection region,
  ) {
    final onlyWalkers = _filters.length == 1 &&
        _filters.contains(MapLayerFilter.walkers);
    if (onlyWalkers) {
      return const [];
    }
    final query = _search.text.trim().toLowerCase();
    final user = ref.read(userLocationProvider).coord;
    final center = mapRegionCenter(region, user);
    final nearbyOnly = _filters.contains(MapLayerFilter.nearby);
    final showAllPlaces = _filters.contains(MapLayerFilter.all) ||
        (_filters.length == 1 && nearbyOnly);
    final selectedTypes = <MapPlaceType>{
      for (final filter in _filters)
        if (filter.placeType != null) filter.placeType!,
    };
    final emergencyOnly = _filters.contains(MapLayerFilter.emergency);

    final result = source.where((place) {
      final haystack = [
        place.name,
        place.neighborhood,
        place.municipality,
        place.type.filterLabel,
        place.type.name,
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      if (!matchesQuery) {
        return false;
      }
      if (!_placeInRegion(place, region, center)) {
        return false;
      }
      if (nearbyOnly) {
        final distance = haversineKm(
          user,
          GeoCoord(place.latitude, place.longitude),
        );
        if (distance > 3) return false;
      }
      if (emergencyOnly && !(place.is24_7 || place.isEmergencyService)) {
        return false;
      }
      if (!showAllPlaces && selectedTypes.isNotEmpty) {
        if (!selectedTypes.contains(place.type)) {
          // Emergency alone can match vets without type chip.
          if (!(emergencyOnly && place.type == MapPlaceType.vet)) {
            return false;
          }
        }
      }
      if (_hotelsSelected && !_matchesHotelAmenities(place)) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      if (a.isSponsored != b.isSponsored) {
        return a.isSponsored ? -1 : 1;
      }
      return b.sponsorPriority.compareTo(a.sponsorPriority);
    });
    return result;
  }

  bool _placeInRegion(
    MapPlace place,
    MapRegionSelection region,
    GeoCoord center,
  ) {
    final cityId = region.cityId;
    if (cityId != null && cityId.isNotEmpty) {
      if (place.cityId == cityId) return true;
      if (place.city != MapCity.other && place.city.cityId == cityId) {
        return true;
      }
    }
    final distance = haversineKm(
      center,
      GeoCoord(place.latitude, place.longitude),
    );
    return distance <= region.radiusKm;
  }

  List<WalkingDogPin> _visibleWalkers(
    List<WalkingDogPin> source,
    MapRegionSelection region,
  ) {
    final showWalkers = _filters.contains(MapLayerFilter.all) ||
        _filters.contains(MapLayerFilter.walkers);
    if (!showWalkers) {
      return const [];
    }
    final query = _search.text.trim().toLowerCase();
    final user = ref.read(userLocationProvider).coord;
    final center = mapRegionCenter(region, user);
    return source.where((pin) {
      final inRegion = haversineKm(
            center,
            GeoCoord(pin.latitude, pin.longitude),
          ) <=
          region.radiusKm;
      if (!inRegion) return false;
      if (query.isEmpty) return true;
      return pin.profile.name.toLowerCase().contains(query) ||
          pin.status.toLowerCase().contains(query);
    }).toList();
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

  void _selectQuickCity(CityModel fallback) {
    final cities =
        ref.read(citiesProvider).asData?.value ?? SeedCities.all;
    final match = cities.where((c) => c.id == fallback.id);
    ref.read(mapRegionProvider.notifier).selectCity(
          match.isNotEmpty ? match.first : fallback,
        );
  }

  Future<void> _applyRegionCamera(MapRegionSelection region) async {
    if (region.isMyLocation) {
      await _goToMyLocation();
      return;
    }
    final city = region.city;
    if (city == null) return;
    await _flyTo(city.center, region.zoom);
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
    const communityPlaceToken = Object();
    const adminPlaceToken = Object();
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
                SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: Text(MapStrings.addPlace),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(communityPlaceToken),
                ),
                if (ref.read(isAdminProvider))
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(MapStrings.addPlaceAdminTitle),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(adminPlaceToken),
                  ),
                const Divider(),
                for (final filter in MapLayerFilterX.extra)
                  ListTile(
                    leading: Icon(filter.placeType?.icon ?? Icons.place),
                    title: Text(filter.label),
                    selected: _filters.contains(filter),
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
    if (identical(selected, communityPlaceToken)) {
      final region = ref.read(mapRegionProvider);
      await showAddPoiSheet(
        context,
        ref,
        initialCity: switch (MapCityX.fromCityId(region.cityId ?? '')) {
          MapCity.other => MapCity.noviSad,
          final city => city,
        },
      );
      return;
    }
    if (identical(selected, adminPlaceToken)) {
      final region = ref.read(mapRegionProvider);
      await openAddPlaceScreen(
        context,
        ref,
        initialCityId: region.cityId,
      );
      return;
    }
    if (selected is MapLayerFilter) {
      _toggleFilter(selected);
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
    final access = await requestLocationPermissionWithDisclosure(
      context: context,
      ref: ref,
    );
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
      final access = await requestLocationPermissionWithDisclosure(
        context: context,
        ref: ref,
      );
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
    final homeCity = ref.read(homeCityProvider)?.name ?? MapStrings.cityNoviSad;
    final body = switch (access) {
      LocationAccess.permanentlyDenied => MapStrings.locationPermanentBody,
      LocationAccess.servicesDisabled =>
        MapStrings.locationDisabledBody(homeCity),
      _ => MapStrings.locationDeniedBody(homeCity),
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
              child: Text(MapStrings.useDefaultCity(homeCity)),
            ),
            if (access == LocationAccess.permanentlyDenied)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(locationClientProvider).openAppSettings();
                },
                child: Text(MapStrings.openSettings),
              )
            else if (access == LocationAccess.denied)
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  if (!mounted) {
                    return;
                  }
                  await requestLocationPermissionWithDisclosure(
                    context: context,
                    ref: ref,
                  );
                },
                child: Text(MapStrings.allowLocation),
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
      onInappropriate: () {
        showContentReportSheet(
          context: context,
          ref: ref,
          targetType: ReportContentType.poi,
          targetId: place.id,
        );
      },
    );
  }

  Future<void> _callPlace(MapPlace place) async {
    final opened = await ref.read(phoneLauncherProvider).call(place.phone);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MapStrings.callFailed)),
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
        SnackBar(content: Text(MapStrings.navigationFailed)),
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
          SnackBar(content: Text(MapStrings.walkRequestSent)),
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
        var selected = controller.text.trim();
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget statusChip(String label) {
              final isSelected = selected == label;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  controller.text = label;
                  setLocalState(() => selected = label);
                },
                selectedColor: const Color(0xFF1D4ED8),
                backgroundColor: const Color(0xFFF3F4F6),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFD1D5DB),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                showCheckmark: false,
              );
            }

            return AlertDialog(
              title: Text(MapStrings.startWalk),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    onChanged: (value) {
                      setLocalState(() => selected = value.trim());
                    },
                    decoration: InputDecoration(
                      labelText: MapStrings.statusLabel,
                      hintText: MapStrings.statusHint,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      statusChip(MapStrings.statusWalking),
                      statusChip(MapStrings.statusResting),
                      statusChip(MapStrings.statusLookingForPlay),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(MapStrings.cancel),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text.trim()),
                  child: Text(MapStrings.confirm),
                ),
              ],
            );
          },
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

/// Dark chip so Lista/Mapa stays readable on the map overlay.
class _MapViewModeChip extends StatelessWidget {
  const _MapViewModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1D4ED8) : const Color(0xFF2A2A38);
    return Material(
      color: bg,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacesListPanel extends StatelessWidget {
  const _PlacesListPanel({
    required this.places,
    required this.userCoord,
    required this.onOpen,
    required this.onDirections,
  });

  final List<MapPlace> places;
  final GeoCoord userCoord;
  final ValueChanged<MapPlace> onOpen;
  final ValueChanged<MapPlace> onDirections;

  static const _bg = Color(0xFFFFFFFF);
  static const _title = Color(0xFF111827);
  static const _body = Color(0xFF374151);
  static const _muted = Color(0xFF6B7280);
  static const _icon = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Material(
        color: _bg,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MapStrings.emptyCategoryTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _title,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                MapStrings.emptyCategoryBody,
                style: TextStyle(color: _body, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <MapPlaceType, List<MapPlace>>{};
    for (final place in places) {
      grouped.putIfAbsent(place.type, () => []).add(place);
    }

    return Material(
      color: _bg,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            Text(
              MapStrings.placesListTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _title,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  entry.key.filterLabel.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.4,
                    color: _muted,
                  ),
                ),
              ),
              for (final place in entry.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: place.pinColor,
                    child: Icon(place.type.icon, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _title,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    [
                      place.municipality.isNotEmpty
                          ? place.municipality
                          : place.address,
                      '${haversineKm(userCoord, GeoCoord(place.latitude, place.longitude)).toStringAsFixed(1)} km',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _body, fontSize: 13),
                  ),
                  trailing: IconButton(
                    tooltip: MapStrings.openNavigation,
                    onPressed: () => onDirections(place),
                    icon: const Icon(Icons.directions, color: _icon),
                  ),
                  onTap: () => onOpen(place),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CityPickerButton extends StatelessWidget {
  const _CityPickerButton({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF1D4ED8) : const Color(0xFF2A2A38);
    return Material(
      color: bg,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.expand_more,
                size: 18,
                color: Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
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

class _WalkStartMarker extends StatelessWidget {
  const _WalkStartMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryDeep, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(
        Icons.flag,
        size: 16,
        color: AppColors.primaryDeep,
      ),
    );
  }
}

class _WalkCurrentMarker extends StatelessWidget {
  const _WalkCurrentMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(
        Icons.directions_walk,
        size: 16,
        color: Colors.white,
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
