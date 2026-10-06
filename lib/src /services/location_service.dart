import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_snapshot.dart';

class LocationService {
  Future<LocationSnapshot> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are turned off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );

    String address = 'Address unavailable';
    try {
      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = <String>[
          if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!.trim(),
          if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
        ];
        address = parts.toSet().join(', ');
      }
    } catch (_) {
      // GPS coordinates are still useful when reverse geocoding is unavailable.
    }

    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: address,
      capturedAt: DateTime.now(),
    );
  }

  /// With [background] true, Android keeps tracking through a foreground
  /// service (persistent notification) and iOS keeps updating in background.
  Stream<Position> watchLocation({bool background = false}) {
    late final LocationSettings settings;
    if (background && defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'WhereWeAre is sharing your live location',
          notificationText: 'Open the app to stop sharing.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (background && defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
