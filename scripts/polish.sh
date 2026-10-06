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
  sed -i '0,/android:label="[^"]*"/s//android:label="WhereWeAre"/' android/app/src/main/AndroidManifest.xml
fi
echo "Icon, splash and app name step finished (iOS=$IOS)."
