import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_snapshot.dart';
import '../models/place_result.dart';
import 'location_service.dart';
import 'saved_places_service.dart';

/// Live sharing via liveShares/{randomToken}. Optional trip destination:
/// the viewer sees the destination, and sharing auto-closes 2 min after arrival.
class LiveShareService {
  /// Set with --dart-define=SHARE_BASE_URL=https://YOUR-PROJECT.web.app
  static const baseUrl = String.fromEnvironment('SHARE_BASE_URL');

  final _loc = LocationService();
  StreamSubscription<Position>? _sub;
  Timer? _timer;
  String? token;
  DateTime? expiresAt;
  VoidCallback? _onEnded;

  bool get active => token != null;
  String get link => '$baseUrl/s/$token';

  static String _newToken() {
    const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> start(
    LocationSnapshot from,
    Duration duration, {
    VoidCallback? onEnded,
    VoidCallback? onArrived,
    PlaceResult? destination,
    bool approximate = false,
    bool hideAddress = false,
    List<SavedPlace> watch = const [],
    void Function(String)? onEvent,
  }) async {
    await stop();
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
    final user = auth.currentUser!;

    double r(double v) => approximate ? (v * 100).roundToDouble() / 100 : v;
    double acc(double a) => approximate ? max(a, 1000.0) : a;
    final inside = <String, bool>{};

    final t = _newToken();
    final exp = DateTime.now().toUtc().add(duration);
    final ref = FirebaseFirestore.instance.collection('liveShares').doc(t);
    await ref.set({
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'Someone',
      'latitude': r(from.latitude),
      'longitude': r(from.longitude),
      'accuracy': acc(from.accuracy),
      'address': hideAddress ? '' : from.address,
      'active': true,
      'arrived': false,
      'approximate': approximate,
      if (destination != null) ...{
        'destName': destination.name,
        'destLat': destination.latitude,
        'destLng': destination.longitude,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(exp),
    });

    token = t;
    expiresAt = exp;
    _onEnded = onEnded;
    _sub = _loc.watchLocation(background: true).listen((p) async {
      final data = <String, dynamic>{
        'latitude': r(p.latitude),
        'longitude': r(p.longitude),
        'accuracy': acc(p.accuracy),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final arrived = destination != null &&
          Geolocator.distanceBetween(p.latitude, p.longitude,
                  destination.latitude, destination.longitude) <
              100;
      if (arrived) data['arrived'] = true;
      for (final w in watch) {
        final d = Geolocator.distanceBetween(p.latitude, p.longitude, w.lat, w.lng);
        final was = inside[w.name];
        // 50 m hysteresis so GPS jitter at the edge does not spam events.
        final now = was == true ? d <= w.radiusM + 50 : d <= w.radiusM;
        if (was != null && was != now) {
          final text = now ? 'Arrived at ${w.name}' : 'Left ${w.name}';
          if (!approximate) {
            data['lastEvent'] = text;
            data['lastEventAt'] = FieldValue.serverTimestamp();
          }
          onEvent?.call(text);
        }
        inside[w.name] = now;
      }
      try {
        await ref.update(data);
      } catch (_) {}
      if (arrived) {
        await _sub?.cancel();
        _sub = null;
        _timer?.cancel();
        _timer = Timer(const Duration(minutes: 2), () async {
          await stop();
          _onEnded?.call();
        });
        onArrived?.call();
      }
    });
    _timer = Timer(duration, () async {
      await stop();
      _onEnded?.call();
    });
  }

  Future<void> stop() async {
    final t = token;
    await _sub?.cancel();
    _timer?.cancel();
    _sub = null;
    _timer = null;
    token = null;
    expiresAt = null;
    if (t != null) {
      try {
        await FirebaseFirestore.instance
            .collection('liveShares')
            .doc(t)
            .update({'active': false});
      } catch (_) {}
    }
  }
}
