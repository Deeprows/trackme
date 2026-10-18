import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

/// True when the build has a Google Maps API key (set by the GitHub workflow
/// when the MAPS_API_KEY secret exists). Without a key the app falls back to
/// OpenStreetMap so it never crashes.
const bool kMapsEnabled = bool.fromEnvironment('MAPS_ENABLED', defaultValue: false);

class AppMapController {
  gm.GoogleMapController? _google;
  final fm.MapController _osm = fm.MapController();

  fm.MapController get osm => _osm;

  void attachGoogle(gm.GoogleMapController c) => _google = c;

  Future<void> move(double lat, double lng, [double zoom = 16]) async {
    try {
      if (kMapsEnabled) {
        await _google?.animateCamera(
          gm.CameraUpdate.newLatLngZoom(gm.LatLng(lat, lng), zoom),
        );
      } else {
        _osm.move(ll.LatLng(lat, lng), zoom);
      }
    } catch (_) {
      // Map not ready yet; ignore.
    }
  }
}

class AppMap extends StatelessWidget {
  final AppMapController controller;
  final double? myLat;
  final double? myLng;
  final String? myAddress;
  final double? placeLat;
  final double? placeLng;
  final String? placeName;

  const AppMap({
    super.key,
    required this.controller,
    this.myLat,
    this.myLng,
    this.myAddress,
    this.placeLat,
    this.placeLng,
    this.placeName,
  });

  static const _cairoLat = 30.0444;
  static const _cairoLng = 31.2357;

  @override
  Widget build(BuildContext context) {
    final hasMe = myLat != null && myLng != null;
    final hasPlace = placeLat != null && placeLng != null;

    if (kMapsEnabled) {
      return gm.GoogleMap(
        initialCameraPosition: const gm.CameraPosition(
          target: gm.LatLng(_cairoLat, _cairoLng),
          zoom: 10,
        ),
        myLocationEnabled: hasMe,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: controller.attachGoogle,
        markers: {
          if (hasPlace)
            gm.Marker(
              markerId: const gm.MarkerId('place'),
              position: gm.LatLng(placeLat!, placeLng!),
              infoWindow: gm.InfoWindow(title: placeName ?? 'Place'),
            ),
          if (hasMe)
            gm.Marker(
              markerId: const gm.MarkerId('me'),
              position: gm.LatLng(myLat!, myLng!),
              infoWindow: gm.InfoWindow(title: 'My location', snippet: myAddress),
            ),
        },
      );
    }

    return fm.FlutterMap(
      mapController: controller.osm,
      options: const fm.MapOptions(
        initialCenter: ll.LatLng(_cairoLat, _cairoLng),
        initialZoom: 10,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.whereweare.whereweare',
        ),
        fm.MarkerLayer(markers: [
          if (hasPlace)
            fm.Marker(
              point: ll.LatLng(placeLat!, placeLng!),
              width: 44,
              height: 44,
              child: const Icon(Icons.place_rounded, color: Colors.red, size: 40),
            ),
          if (hasMe)
            fm.Marker(
              point: ll.LatLng(myLat!, myLng!),
              width: 44,
              height: 44,
              child: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF2563EB), size: 32),
            ),
        ]),
        const fm.RichAttributionWidget(attributions: [
          fm.TextSourceAttribution('© OpenStreetMap contributors'),
        ]),
      ],
    );
  }
}
