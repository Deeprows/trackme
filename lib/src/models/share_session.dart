class ShareSession {
  final String id;
  final String ownerId;
  final String ownerName;
  final DateTime expiresAt;
  final bool active;

  const ShareSession({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.expiresAt,
    required this.active,
  });

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'expiresAt': expiresAt.toUtc(),
        'active': active,
      };
}
