# WhereWeAre architecture

## Client

Flutter app:
- Home/map
- Current location
- Place search
- Share flow
- Family circles
- SOS
- Settings/privacy

## Backend

Firebase Authentication:
- anonymous sign-in for early testing
- later upgrade to email, phone, Google, Apple, etc.

Cloud Firestore:
- users/{uid}
- groups/{groupId}
- shareSessions/{sessionId}
- locationUpdates/{sessionId}/points/{pointId} for future live tracking

Firebase Cloud Messaging:
- share requests
- accepted shares
- arrival/departure alerts
- SOS notifications

## Important privacy rule

Never make a user's live location queryable by username alone. A viewer should receive access only through an explicit relationship or a random, expiring share token.

## Future share web viewer

Recommended URL:

https://YOUR-DOMAIN/share/<random-token>

The token should be high entropy and map server-side to a session. Do not put raw Firestore IDs into public URLs.

## Data retention

Suggested defaults:
- one-time location: delete after share expires
- live session: delete location updates after 24 hours
- history: opt-in, configurable retention
- revoked session: immediately inaccessible
