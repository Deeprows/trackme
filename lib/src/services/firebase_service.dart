import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/location_snapshot.dart';

class FirebaseService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserCredential> signInAnonymously() {
    return auth.signInAnonymously();
  }

  Future<String> createShareSession({
    required LocationSnapshot location,
    required Duration duration,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to create a share session.');
    }

    final ref = firestore.collection('shareSessions').doc();
    final expiresAt = DateTime.now().toUtc().add(duration);

    await ref.set({
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'WhereWeAre user',
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'address': location.address,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'active': true,
    });

    return ref.id;
  }

  Future<void> revokeShareSession(String sessionId) async {
    await firestore.collection('shareSessions').doc(sessionId).update({
      'active': false,
      'revokedAt': FieldValue.serverTimestamp(),
    });
  }
}
