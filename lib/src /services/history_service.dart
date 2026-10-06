import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_snapshot.dart';

class HistoryEntry {
  final double lat, lng;
  final String address;
  final DateTime at;
  const HistoryEntry(this.lat, this.lng, this.address, this.at);

  Map<String, dynamic> toJson() =>
      {'lat': lat, 'lng': lng, 'address': address, 'at': at.toIso8601String()};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
      (j['lat'] as num).toDouble(),
      (j['lng'] as num).toDouble(),
      j['address'] as String,
      DateTime.parse(j['at'] as String));
}

/// Opt-in, on-device only, auto-deleted after the retention period.
class HistoryService {
  static const _key = 'location_history';

  Future<List<HistoryEntry>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<HistoryEntry> l) async => (await SharedPreferences.getInstance())
      .setString(_key, jsonEncode(l.map((e) => e.toJson()).toList()));

  Future<void> add(LocationSnapshot s, int retentionDays) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final list = (await load()).where((e) => e.at.isAfter(cutoff)).toList();
    list.insert(0, HistoryEntry(s.latitude, s.longitude, s.address, s.capturedAt));
    await _save(list.take(500).toList());
  }

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);
}
