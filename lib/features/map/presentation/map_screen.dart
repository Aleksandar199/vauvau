import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/presentation/widgets/scheduled_walks_banner.dart';
import '../../home/presentation/home_tab.dart';
import '../data/mock_map_data.dart';
import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/walk_session.dart';
import '../domain/walking_dog_pin.dart';
import 'map_strings.dart';
import 'walk_controller.dart';
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
    final places = _visiblePlaces(ref.watch(mapPlacesProvider));
    final walkers = _visibleWalkers(ref.watch(walkingDogsProvider));

    return Stack(
      children: [
        Positioned.fill(
          child: VauInteractiveMap(
            controller: _mapController,
            markers: [
            for (final place in places)
              Marker(
                point: LatLng(place.latitude, place.longitude),
                width: 56,
                height: 64,
                child: PlacePin(
                  place: place,
                  selected: _selectedId == place.id,
                  onTap: () => _selectPlace(place),
                ),
              ),
            for (final walker in walkers)
              Marker(
                point: LatLng(walker.latitude, walker.longitude),
                width: 56,
                height: 56,
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
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: MapStrings.searchHint,
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: MapStrings.filterAll,
                      selected: _filter == MapLayerFilter.all,
                      onTap: () => setState(() => _filter = MapLayerFilter.all),
                    ),
                    _FilterChip(
                      label: MapStrings.filterParks,
                      selected: _filter == MapLayerFilter.parks,
                      onTap: () =>
                          setState(() => _filter = MapLayerFilter.parks),
                    ),
                    _FilterChip(
                      label: MapStrings.filterCafes,
                      selected: _filter == MapLayerFilter.cafes,
                      onTap: () =>
                          setState(() => _filter = MapLayerFilter.cafes),
                    ),
                    _FilterChip(
                      label: MapStrings.filterWalkers,
                      selected: _filter == MapLayerFilter.walkers,
                      onTap: () =>
                          setState(() => _filter = MapLayerFilter.walkers),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (walk.isActive) _WalkBanner(walk: walk),
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
                onPressed: _recenterLiman,
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: walk.isActive
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      ref.read(walkControllerProvider.notifier).end(),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  icon: const Icon(Icons.stop),
                  label: const Text(MapStrings.endWalk),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _promptStartWalk(context),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text(MapStrings.startWalk),
                ),
        ),
      ],
    );
  }

  List<MapPlace> _visiblePlaces(List<MapPlace> source) {
    final query = _search.text.trim().toLowerCase();
    return source.where((place) {
      final matchesQuery = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.neighborhood.toLowerCase().contains(query);
      if (!matchesQuery) {
        return false;
      }
      if (_filter == MapLayerFilter.walkers) {
        return false;
      }
      if (_filter == MapLayerFilter.parks) {
        return place.type == MapPlaceType.park;
      }
      if (_filter == MapLayerFilter.cafes) {
        return place.type == MapPlaceType.cafe;
      }
      return true;
    }).toList();
  }

  List<WalkingDogPin> _visibleWalkers(List<WalkingDogPin> source) {
    if (_filter == MapLayerFilter.parks || _filter == MapLayerFilter.cafes) {
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

  void _zoomBy(double delta) {
    try {
      final camera = _mapController.camera;
      _mapController.move(
        camera.center,
        (camera.zoom + delta).clamp(11, 18).toDouble(),
      );
    } catch (_) {}
  }

  void _recenterLiman() {
    try {
      _mapController.move(const LatLng(limanLat, limanLng), limanZoom);
    } catch (_) {}
  }

  Future<void> _selectPlace(MapPlace place) async {
    setState(() => _selectedId = place.id);
    try {
      _mapController.move(LatLng(place.latitude, place.longitude), 16);
    } catch (_) {}
    await showPlaceSheet(
      context: context,
      place: place,
      onJoin: () => _promptStartWalk(
        context,
        preset: '${MapStrings.joinWalkStatusPrefix} ${place.name}',
      ),
      onDirections: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(MapStrings.directionsSoon)),
        );
      },
    );
  }

  Future<void> _selectWalker(WalkingDogPin pin) async {
    setState(() => _selectedId = pin.profile.id);
    try {
      _mapController.move(LatLng(pin.latitude, pin.longitude), 16);
    } catch (_) {}
    await showWalkerSheet(
      context: context,
      pin: pin,
      onOpenChat: () {
        final chatId =
            ref.read(chatInboxProvider.notifier).openFromMatch(pin.profile);
        ref.read(homeTabIndexProvider.notifier).showMessages();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(conversationId: chatId),
          ),
        );
      },
    );
  }

  Future<void> _promptStartWalk(BuildContext context, {String? preset}) async {
    final controller = TextEditingController(text: preset ?? '');
    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(MapStrings.startWalk),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: MapStrings.statusLabel,
              hintText: MapStrings.statusHint,
            ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
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
