import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock_map_data.dart';

class VauInteractiveMap extends StatelessWidget {
  const VauInteractiveMap({
    super.key,
    required this.controller,
    required this.markers,
  });

  final MapController controller;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: const LatLng(mapCenterLat, mapCenterLng),
        initialZoom: defaultMapZoom,
        minZoom: 11,
        maxZoom: 19,
        initialCameraFit: CameraFit.coordinates(
          coordinates: const [
            LatLng(noviSadLat, noviSadLng),
            LatLng(limanLat, limanLng),
            LatLng(45.2285, 19.8130),
            LatLng(45.2598, 19.8504),
          ],
          padding: EdgeInsets.fromLTRB(28, 150, 28, 110),
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
        _UnculledMarkerLayer(markers: markers),
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
