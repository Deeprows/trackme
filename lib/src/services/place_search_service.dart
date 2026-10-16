import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_result.dart';

/// Searches places by name (schools, hospitals, malls, landmarks, addresses)
/// using OpenStreetMap Nominatim. No API key needed. For production traffic,
/// move this behind your own backend or switch to Google Places.
class PlaceSearchService {
  Future<List<PlaceResult>> search(String query,
      {double? nearLat, double? nearLng}) async {
    final params = {
      'q': query,
      'format': 'jsonv2',
      'limit': '10',
      if (nearLat != null && nearLng != null)
        'viewbox':
            '${nearLng - 0.5},${nearLat + 0.5},${nearLng + 0.5},${nearLat - 0.5}',
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final res = await http
        .get(uri, headers: {'User-Agent': 'WhereWeAre/0.1 (Flutter app)'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode}). Try again.');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final full = (m['display_name'] as String?) ?? '';
      final name = (m['name'] as String?)?.trim().isNotEmpty == true
          ? m['name'] as String
          : full.split(',').first;
      return PlaceResult(
        name: name,
        address: full,
        latitude: double.parse(m['lat'] as String),
        longitude: double.parse(m['lon'] as String),
      );
    }).toList();
  }
}
