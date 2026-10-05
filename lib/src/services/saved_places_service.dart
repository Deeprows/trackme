import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPlace {
  final String name;
  final String address;
  final double lat, lng;
  final double radiusM;
  final bool alerts; // announce arrive/leave on live links

  const SavedPlace({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.radiusM = 150,
    this.alerts = false,
  });

  SavedPlace withAlerts(bool v) => SavedPlace(
      name: name, address: address, lat: lat, lng: lng, radiusM: radiusM, alerts: v);

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'radius': radiusM,
        'alerts': alerts,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> j) => SavedPlace(
        name: j['name'] as String,
        address: j['address'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusM: (j['radius'] as num?)?.toDouble() ?? 150,
        alerts: j['alerts'] == true,
      );
}

/// Home, School, Work and other places, stored on this phone only.
class SavedPlacesService {
  static const _key = 'saved_places';

  Future<List<SavedPlace>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => SavedPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<SavedPlace> l) async =>
      (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode(l.map((e) => e.toJson()).toList()));

  Future<void> add(SavedPlace p) async => save([...await load(), p]);
}
