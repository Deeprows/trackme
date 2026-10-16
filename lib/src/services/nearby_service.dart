import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/place_result.dart';

/// Nearby places from OpenStreetMap (Overpass API). No key needed.
class NearbyService {
  static const categories = {
    'Hospital': 'amenity=hospital',
    'Pharmacy': 'amenity=pharmacy',
    'Police': 'amenity=police',
    'School': 'amenity=school',
    'Fuel': 'amenity=fuel',
    'ATM': 'amenity=atm',
    'Restaurant': 'amenity=restaurant',
    'Supermarket': 'shop=supermarket',
  };

  Future<List<PlaceResult>> search(String category, double lat, double lng,
      {int radius = 3000}) async {
    final kv = categories[category]!.split('=');
    final q = '[out:json][timeout:20];'
        'nwr(around:$radius,$lat,$lng)["${kv[0]}"="${kv[1]}"];out center 60;';
    final res = await http.post(
      Uri.https('overpass-api.de', '/api/interpreter'),
      headers: {'User-Agent': 'WhereWeAre/0.1 (Flutter app)'},
      body: {'data': q},
    ).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw Exception('Nearby search failed (${res.statusCode}).');
    final out = <PlaceResult>[];
    for (final e in (jsonDecode(res.body)['elements'] as List<dynamic>)) {
      final m = e as Map<String, dynamic>;
      final c = m['center'] as Map<String, dynamic>?;
      final pLat = ((m['lat'] ?? c?['lat']) as num?)?.toDouble();
      final pLng = ((m['lon'] ?? c?['lon']) as num?)?.toDouble();
      if (pLat == null || pLng == null) continue;
      final t = (m['tags'] as Map<String, dynamic>?) ?? {};
      final street = [t['addr:housenumber'], t['addr:street'], t['addr:city']]
          .whereType<String>()
          .join(' ');
      out.add(PlaceResult(
        name: (t['name'] as String?) ?? category,
        address: street.isEmpty ? 'Nearby $category' : street,
        latitude: pLat,
        longitude: pLng,
        distanceM: Geolocator.distanceBetween(lat, lng, pLat, pLng),
        phone: (t['phone'] ?? t['contact:phone']) as String?,
        hours: t['opening_hours'] as String?,
        website: (t['website'] ?? t['contact:website']) as String?,
      ));
    }
    out.sort((a, b) => a.distanceM!.compareTo(b.distanceM!));
    return out.take(25).toList();
  }
}
