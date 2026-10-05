#!/usr/bin/env bash
# Generates app icon + native splash and sets the app name. Run after flutter create.
set -euo pipefail
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart run flutter_native_splash:create --path=flutter_native_splash.yaml
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i '0,/android:label="[^"]*"/s//android:label="WhereWeAre"/' android/app/src/main/AndroidManifest.xml
fi
echo "Icon, splash and app name done."
