#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed. Install Flutter in this Codespace first."
  exit 1
fi

flutter create . --platforms=android,ios --org=com.whereweare --project-name=whereweare
flutter pub get
bash scripts/polish.sh
echo "Flutter platform projects created."
