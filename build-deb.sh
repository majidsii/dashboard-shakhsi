#!/usr/bin/env bash
# Build the dashboard-shakhsi .deb package into dist/
set -euo pipefail
cd "$(dirname "$0")"

NAME=dashboard-shakhsi
VERSION=$(cat VERSION)
ARCH=all
ROOT="build/${NAME}_${VERSION}_${ARCH}"
OUT=dist

rm -rf build "$OUT"
mkdir -p "$OUT"

install -d \
  "$ROOT/DEBIAN" \
  "$ROOT/usr/bin" \
  "$ROOT/usr/share/$NAME/fonts" \
  "$ROOT/usr/share/applications" \
  "$ROOT/usr/share/doc/$NAME" \
  "$ROOT/usr/share/icons/hicolor/scalable/apps"
for s in 128 256 512; do
  install -d "$ROOT/usr/share/icons/hicolor/${s}x${s}/apps"
done

# app
install -m644 src/app.html                        "$ROOT/usr/share/$NAME/"
install -m755 src/main.py                         "$ROOT/usr/share/$NAME/"
install -m644 src/fonts/Vazirmatn-Variable.woff2  "$ROOT/usr/share/$NAME/fonts/"

# launcher
printf '#!/bin/sh\nexec python3 /usr/share/%s/main.py "$@"\n' "$NAME" \
  > "$ROOT/usr/bin/$NAME"
chmod 755 "$ROOT/usr/bin/$NAME"

# desktop entry + icons
install -m644 "packaging/$NAME.desktop" "$ROOT/usr/share/applications/"
install -m644 assets/icon.svg "$ROOT/usr/share/icons/hicolor/scalable/apps/$NAME.svg"
for s in 128 256 512; do
  install -m644 "assets/icons/$NAME-$s.png" \
    "$ROOT/usr/share/icons/hicolor/${s}x${s}/apps/$NAME.png"
done

# docs
install -m644 packaging/README.deb "$ROOT/usr/share/doc/$NAME/README"
install -m644 src/fonts/OFL.txt    "$ROOT/usr/share/doc/$NAME/OFL-Vazirmatn.txt"

# control
SIZE=$(du -sk "$ROOT/usr" | cut -f1)
sed -e "s/@VERSION@/$VERSION/" -e "s/@SIZE@/$SIZE/" \
  packaging/control.in > "$ROOT/DEBIAN/control"

dpkg-deb --build --root-owner-group "$ROOT" "$OUT/${NAME}_${VERSION}_${ARCH}.deb"
echo
echo "Built: $OUT/${NAME}_${VERSION}_${ARCH}.deb"
echo "Install with: sudo apt install ./$OUT/${NAME}_${VERSION}_${ARCH}.deb"
