# WhereWeAre

A privacy-first Flutter app for sharing current location with family and friends, finding places by name, viewing exact addresses, and creating temporary location-sharing sessions.

## MVP

- Current GPS location
- Reverse geocoded address
- Google Maps map
- Search a place by name
- Share exact location using the device share sheet
- Firebase email/password authentication
- Firestore location-sharing sessions
- Family/friend contact architecture
- SOS flow
- Expiring share sessions
- Push-notification foundation

## Stack

Flutter + Firebase Authentication + Cloud Firestore + Firebase Cloud Messaging + Geolocator + Google Maps for Flutter.

Current package versions were checked against pub.dev on 2026-10-05.

## 1. Create the Flutter platform folders

In GitHub Codespaces:

```bash
bash scripts/bootstrap.sh
```

This runs `flutter create` and creates the Android/iOS platform projects without overwriting the Dart source.

## 2. Firebase

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Then:

```bash
flutterfire configure
```

Select your Firebase project and Android/iOS platforms. The command generates `lib/firebase_options.dart`.

Enable in Firebase Console:

- Authentication -> Email/Password
- Firestore Database
- Cloud Messaging

Then deploy the included Firestore rules:

```bash
firebase deploy --only firestore:rules
```

You need the Firebase CLI installed and logged in for that command.

## 3. Google Maps

Create a Google Maps Platform project and enable Maps SDK for Android/iOS. The Flutter Maps plugin requires an API key and platform-specific setup.

For Android, add your restricted Maps key to:

`android/app/src/main/AndroidManifest.xml`

inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_KEY"/>
```

For iOS, configure the Maps key in `ios/Runner/AppDelegate.swift`.

Do not commit unrestricted production API keys.

## 4. Run

```bash
flutter pub get
flutter run
```

For a local demo without Firebase configuration:

```bash
flutter run --dart-define=USE_FIREBASE=false
```

For the real backend:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

## 5. Build APK

```bash
flutter build apk --release --dart-define=USE_FIREBASE=true
```

## Security

Location is private by design. Sharing must be explicitly started. Sessions contain an expiry timestamp and can be revoked. Firestore rules deny arbitrary reads/writes outside the authenticated user's permitted data.

Before production, add App Check, rate limits, abuse reporting, audit logging, server-side token generation, and a web viewer that uses random share tokens rather than exposing Firestore IDs.

## Planned v2

- Family circles
- Contact invitations
- Live background location
- Geofences
- Arrival/departure alerts
- One-time web viewer links
- Places/nearby search through a backend
- Trip tracking
- Emergency contact workflow
- Location history with user-controlled retention

## Added in this build

- Place search by name (schools, hospitals, malls, addresses) via OpenStreetMap Nominatim, no key needed. Tap a result to see it on the map, share it, or get directions.
- Family & friends list (stored on the device) with one-tap send by SMS or WhatsApp.
- SOS prepares an SMS with your exact location to all saved contacts.
- Copy address and map link.

### Android permissions (add after running bootstrap.sh)

In `android/app/src/main/AndroidManifest.xml`, before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
</queries>
```

## Live sharing link

1. In Firebase Console enable **Authentication > Anonymous** and **Hosting**.
2. Paste your Firebase *web app* config into `firebase/public/index.html`.
3. Deploy: `firebase deploy --only firestore:rules,hosting`
4. Run the app with your hosting URL:
   `flutter run --dart-define=USE_FIREBASE=true --dart-define=SHARE_BASE_URL=https://YOUR-PROJECT.web.app`

Links look like `https://YOUR-PROJECT.web.app/s/<24-char random token>`. They stop working when you press Stop or the timer ends. Sessions are capped at 24 h by the rules. Sharing keeps running when you leave the app: Android shows a persistent "sharing your live location" notification (foreground service), iOS shows the blue location indicator. Optional: add a Firestore TTL policy on `liveShares.expiresAt` to auto-delete old sessions.

### Background sharing setup

Android: add these next to the other permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

iOS: in `ios/Runner/Info.plist` add `NSLocationWhenInUseUsageDescription` (and `NSLocationAlwaysAndWhenInUseUsageDescription`), plus:

```xml
<key>UIBackgroundModes</key><array><string>location</string></array>
```

Start sharing while the app is open; the service cannot be started from the background. Some phone makers (Xiaomi, Huawei, Samsung) kill background apps aggressively, so tell users to set battery to "Unrestricted" for WhereWeAre. Swiping the app away may end tracking; viewers then see the last position until the timer expires.

## v5 features

- **Trip sharing:** pick a destination (Share a trip, or "Share my trip here" in place details). The live link shows the destination; sharing auto-closes 2 minutes after you arrive (within 100 m).
- **Emergency contacts:** star contacts in Family & friends. SOS texts the starred ones (or everyone if none starred). Call button on every contact.
- **Location history:** opt-in, stored on the phone only, auto-deleted after 1, 7 or 30 days, delete-all button.
- **Privacy controls (shield icon):** history on/off and retention, approximate location (about 1 km) and hidden address for live links, delete all local data.
- **Nearby places:** hospitals, pharmacies, police, schools, fuel, ATMs, restaurants, supermarkets within 3 km (OpenStreetMap Overpass).
- **Place details and directions:** distance and rough ETA per travel mode, then opens Google Maps directions for driving, walking, cycling or transit. Phone, opening hours and website show when OpenStreetMap has them.

Add to the `<queries>` block in AndroidManifest.xml for call buttons:
`<intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>`

Redeploy the web viewer (`firebase deploy --only hosting`) so it shows destinations.

## v6: saved places and arrival/departure alerts

- **Saved places** (bookmark icon in the top bar): save your current spot as Home, School, Work or any name. Tap one to show it on the map. You can also save any searched place from its details page.
- **Arrival/departure alerts:** switch a saved place on, then start a live share. When you arrive at or leave it (150 m radius, with a 50 m buffer against GPS jitter), the live link shows "Arrived at School" / "Left Home" with the time, and you see a confirmation in the app. Works in the background through the same foreground service as live sharing.
- Alerts only run while a live share is active, and are not written to the link when "Approximate location" is on, so approximate sharing never reveals named places.
- Viewers see the update when they have the link open. Push notifications to family phones need a Cloud Function plus FCM tokens (planned next).

Redeploy the web viewer: `firebase deploy --only hosting`.

## v7: one-tap check-in

The **Check in** tile sends "I'm safe", "I've arrived" or "Running late" with your exact address and map link to your starred emergency contacts (or everyone if none are starred). If a live share is running, the live link is included. It opens your SMS app prefilled, so nothing is sent until you press send.

## v8: polish

- **App icon and splash:** generated from `assets/icon/`. `scripts/bootstrap.sh` (and the GitHub workflow) now run `scripts/polish.sh`, which creates the launcher icons, native splash and sets the app name to WhereWeAre. Replace the PNGs in `assets/icon/` to rebrand, then run `bash scripts/polish.sh`.
- **Onboarding:** 4 first-run screens explain the privacy model (you choose when to share, expiring private links, data stays on the phone, safety tools). Shown once.
- **Languages:** English, Arabic (right-to-left works automatically) and Spanish, with a language picker in Privacy & settings (default: phone language). Strings live in `lib/src/l10n/strings.dart`; add a key to all three maps to translate more.
- Fixed a compile error in the starter's `home_screen.dart` (a quoted string had a raw line break).
