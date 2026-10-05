class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final DateTime capturedAt;

  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.capturedAt,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'address': address,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };
}
