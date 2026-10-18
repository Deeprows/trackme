# Google Maps setup (GitHub Actions build)

The workflow reads your Maps key from a GitHub secret named `MAPS_API_KEY`,
adds it to the Android manifest during the build, and turns on the Google map.
With no secret, the app uses an OpenStreetMap map instead (it never crashes).

1. Google Cloud Console (console.cloud.google.com): create or pick a project.
2. Billing: link a billing account (Maps requires it; Google gives a monthly free credit).
3. APIs & Services > Library: enable **Maps SDK for Android**.
4. APIs & Services > Credentials > Create credentials > **API key**.
5. Edit the key > API restrictions > Restrict key > tick **Maps SDK for Android** only.
   Leave application restrictions as "None" for now. CI builds are signed with a new
   debug key each run, so an Android-app restriction (package + SHA-1) would block the map.
6. GitHub repo > Settings > Secrets and variables > Actions > New repository secret:
   Name `MAPS_API_KEY`, value = your key.
7. Actions tab > Build Android APK > Run workflow. In the "Icon, splash, permissions and
   Maps key" step the log should say "Google Maps key added to manifest."
8. Download the APK artifact, uninstall the old app, install the new one.

Troubleshooting: a blank grey map means the key is wrong, Maps SDK for Android is not
enabled, or billing is not active. `adb logcat | grep -i "Google Maps"` shows the exact reason.
