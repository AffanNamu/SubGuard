#!/usr/bin/env bash
# Rebuilds every app icon from design/icon/source.png.
#
#   tool/generate_icons.sh
#
# 1. tool/make_icons.py cuts the artwork into the layers the stores need.
# 2. flutter_launcher_icons writes the Android and iOS icon files.
# 3. The generator wraps the Android adaptive foreground in a 16% inset. The
#    foreground made in step 1 already leaves the safe-zone margin, so the
#    inset is removed; otherwise the mark would shrink twice.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 tool/make_icons.py
dart run flutter_launcher_icons

cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@drawable/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
XML
