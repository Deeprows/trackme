class PlaceResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceM;
  final String? phone;
  final String? hours;
  final String? website;

  const PlaceResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceM,
    this.phone,
    this.hours,
    this.website,
  });
}

String formatDistance(double m) =>
    m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
