import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock_map_data.dart';
import 'osm_tile_layer.dart';

class VauInteractiveMap extends StatefulWidget {
  const VauInteractiveMap({
    super.key,
    required this.controller,
    required this.placeMarkers,
    required this.overlayMarkers,
    this.routePoints = const [],
    this.routeColor = const Color(0xFFEA580C),
    this.initialCenter,
    this.initialZoom,
  });

  final MapController controller;
  /// Start camera (e.g. user's home city). Null keeps the Novi Sad fit.
  final LatLng? initialCenter;
  final double? initialZoom;
  final List<Marker> placeMarkers;
  final List<Marker> overlayMarkers;
  final List<LatLng> routePoints;
  final Color routeColor;

  @override
  State<VauInteractiveMap> createState() => _VauInteractiveMapState();
}

class _VauInteractiveMapState extends State<VauInteractiveMap> {
  /// Stable [MapOptions] — recreating options on every parent rebuild resets
  /// the camera and makes tiles/markers flicker during an active walk.
  late final MapOptions _mapOptions = MapOptions(
    initialCenter:
        widget.initialCenter ?? const LatLng(mapCenterLat, mapCenterLng),
    initialZoom: widget.initialZoom ?? defaultMapZoom,
    minZoom: 10,
    maxZoom: 19,
    initialCameraFit: widget.initialCenter != null
        ? null
        : CameraFit.coordinates(
            coordinates: const [
              LatLng(noviSadLat, noviSadLng),
              LatLng(limanLat, limanLng),
              LatLng(45.2285, 19.8130),
              LatLng(45.2598, 19.8504),
            ],
            padding: const EdgeInsets.fromLTRB(28, 150, 28, 110),
            maxZoom: defaultMapZoom,
          ),
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RepaintBoundary(
        child: FlutterMap(
          mapController: widget.controller,
          options: _mapOptions,
          children: [
            buildOsmTileLayer(),
            if (widget.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    color: widget.routeColor,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                    borderStrokeWidth: 0,
                  ),
                ],
              ),
            if (widget.placeMarkers.isNotEmpty)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: widget.placeMarkers,
                  maxClusterRadius: 72,
                  disableClusteringAtZoom: 12,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  maxZoom: 17,
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D3E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${markers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            _UnculledMarkerLayer(markers: widget.overlayMarkers),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnculledMarkerLayer extends StatelessWidget {
  const _UnculledMarkerLayer({required this.markers});

  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);

    return MobileLayerTransformer(
      child: Stack(
        children: [
          for (final marker in markers)
            Builder(
              builder: (context) {
                final offset = map.getOffsetFromOrigin(marker.point);
                final left =
                    offset.dx.isFinite ? offset.dx - marker.width / 2 : 0.0;
                final top =
                    offset.dy.isFinite ? offset.dy - marker.height : 0.0;
                return Positioned(
                  left: left,
                  top: top,
                  width: marker.width,
                  height: marker.height,
                  child: marker.child,
                );
              },
            ),
        ],
      ),
    );
  }
}
