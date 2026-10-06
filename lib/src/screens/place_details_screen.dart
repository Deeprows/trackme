import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';
import '../services/saved_places_service.dart';
import '../services/share_service.dart';

/// Pops with 'trip' when the user wants to share a live trip to this place.
class PlaceDetailsScreen extends StatefulWidget {
  final PlaceResult place;
  final LocationSnapshot? from;
  const PlaceDetailsScreen({super.key, required this.place, this.from});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final share = ShareService();
  String mode = 'driving';

  // Rough average speeds in km/h for straight-line estimates.
  static const speeds = {'driving': 35.0, 'walking': 5.0, 'bicycling': 15.0, 'transit': 25.0};

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final f = widget.from;
    final meters = f == null
        ? p.distanceM
        : Geolocator.distanceBetween(f.latitude, f.longitude, p.latitude, p.longitude);
    final mins = meters == null ? null : (meters / 1000 / speeds[mode]! * 60).ceil();

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(p.address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
            style: TextStyle(color: Colors.grey.shade700)),
        if (meters != null) ...[
          const SizedBox(height: 12),
          Text('${formatDistance(meters)} away in a straight line · about $mins min by $mode (estimate)'),
        ],
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'driving', icon: Icon(Icons.directions_car_rounded)),
            ButtonSegment(value: 'walking', icon: Icon(Icons.directions_walk_rounded)),
            ButtonSegment(value: 'bicycling', icon: Icon(Icons.directions_bike_rounded)),
            ButtonSegment(value: 'transit', icon: Icon(Icons.directions_transit_rounded)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => setState(() => mode = s.first),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => share.openDirections(p.latitude, p.longitude, mode: mode),
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Start directions'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.pop(context, 'trip'),
          icon: const Icon(Icons.route_rounded),
          label: const Text('Share my trip here (live link)'),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => share.sharePlace(p),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share place'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: '${p.name}\n${p.address}\n${ShareService.mapUrl(p.latitude, p.longitude)}'));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await SavedPlacesService().add(SavedPlace(
                name: p.name, address: p.address, lat: p.latitude, lng: p.longitude));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Saved to Saved places')));
            }
          },
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save place'),
        ),
        if (p.phone != null || p.hours != null || p.website != null) const Divider(height: 32),
        if (p.phone != null)
          ListTile(
              leading: const Icon(Icons.call_rounded),
              title: Text(p.phone!),
              onTap: () => share.call(p.phone!)),
        if (p.hours != null)
          ListTile(leading: const Icon(Icons.schedule_rounded), title: Text(p.hours!)),
        if (p.website != null)
          ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(p.website!),
              onTap: () => launchUrl(Uri.parse(p.website!), mode: LaunchMode.externalApplication)),
      ]),
    );
  }
}
