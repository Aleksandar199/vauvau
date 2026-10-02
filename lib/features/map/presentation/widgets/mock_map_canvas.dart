import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock_map_data.dart';

class VauInteractiveMap extends StatelessWidget {
  const VauInteractiveMap({
    super.key,
    required this.controller,
    required this.placeMarkers,
    required this.overlayMarkers,
    this.routePoints = const [],
    this.routeColor = const Color(0xFFEA580C),
  });

  final MapController controller;
  final List<Marker> placeMarkers;
  final List<Marker> overlayMarkers;
  final List<LatLng> routePoints;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: const LatLng(mapCenterLat, mapCenterLng),
          initialZoom: defaultMapZoom,
          minZoom: 10,
          maxZoom: 19,
          initialCameraFit: CameraFit.coordinates(
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
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.vauvau',
            tileProvider: NetworkTileProvider(),
            maxZoom: 19,
            maxNativeZoom: 19,
          ),
          if (routePoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: routeColor,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                  borderStrokeWidth: 0,
                ),
              ],
            ),
          if (placeMarkers.isNotEmpty)
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                markers: placeMarkers,
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
          _UnculledMarkerLayer(markers: overlayMarkers),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [
              TextSourceAttribution('OpenStreetMap'),
            ],
          ),
        ],
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
