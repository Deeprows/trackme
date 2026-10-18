#!/usr/bin/env bash
# Generates app icon + native splash and sets the app name. Run after flutter create.
# Self-contained: configs are written here, so stale yaml files cannot cause problems.
# iOS assets are generated only when an ios/ folder exists (the CI build is Android-only).
set -uo pipefail
IOS=false
[ -d ios ] && IOS=true

cat > /tmp/icons.yaml <<YAML
flutter_launcher_icons:
  android: true
  ios: $IOS
  image_path: assets/icon/icon.png
  adaptive_icon_background: "#2563EB"
  adaptive_icon_foreground: assets/icon/icon_fg.png
YAML

cat > /tmp/splash.yaml <<YAML
flutter_native_splash:
  android: true
  ios: $IOS
  web: false
  color: "#2563EB"
  image: assets/icon/splash_logo.png
  android_12:
    color: "#2563EB"
    image: assets/icon/splash_logo.png
YAML

flutter pub get || exit 1
dart run flutter_launcher_icons -f /tmp/icons.yaml || echo "WARNING: icon generation failed (cosmetic, continuing)"
dart run flutter_native_splash:create --path=/tmp/splash.yaml || echo "WARNING: splash generation failed (cosmetic, continuing)"
if [ -f android/app/src/main/AndroidManifest.xml ]; then
python3 - <<'PY'
import os, re
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()

# App name
s = re.sub(r'android:label="[^"]*"', 'android:label="WhereWeAre"', s, count=1)

# Permissions the app needs (location, internet, live-sharing foreground service)
perms = ['INTERNET', 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
         'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_LOCATION', 'POST_NOTIFICATIONS']
block = ''.join('    <uses-permission android:name="android.permission.%s"/>\n' % x
                for x in perms if 'android.permission.%s"' % x not in s)
intents = ('        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>\n'
           '        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>\n')
if '<queries>' in s:
    s = s.replace('</queries>', intents + '    </queries>', 1)
else:
    block += '    <queries>\n' + intents + '    </queries>\n'
s = s.replace('<application', block + '    <application', 1)

meta = ''
# Some devices never draw the first frame with Impeller and stay on the splash.
if 'EnableImpeller' not in s:
    meta += '        <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="false"/>\n'
# Google Maps key comes from the MAPS_API_KEY GitHub secret
key = os.environ.get('MAPS_API_KEY', '').strip()
if key and 'com.google.android.geo.API_KEY' not in s:
    meta += '        <meta-data android:name="com.google.android.geo.API_KEY" android:value="%s"/>\n' % key
    print('Google Maps key added to manifest.')
elif not key:
    print('No MAPS_API_KEY secret: the app will use the OpenStreetMap fallback map.')
s = s.replace('</application>', meta + '    </application>', 1)
open(p, 'w', encoding='utf-8').write(s)
PY
fi
echo "Icon, splash and app name step finished (iOS=$IOS)."
