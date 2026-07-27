#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_HTML="$APP_DIR/../src/app.html"
FONT_DIR="$APP_DIR/assets/fonts/vazirmatn"
WOFF2_FILE="$FONT_DIR/Vazirmatn-Variable.woff2"
TTF_FILE="$FONT_DIR/Vazirmatn-Variable.ttf"
PUBSPEC="$APP_DIR/pubspec.yaml"

if [[ ! -f "$SOURCE_HTML" ]]; then
  echo "Original UI source not found: $SOURCE_HTML" >&2
  exit 1
fi

if ! command -v woff2_decompress >/dev/null 2>&1; then
  echo "Missing woff2_decompress. Install it with: sudo apt install -y woff2" >&2
  exit 1
fi

mkdir -p "$FONT_DIR"

python3 - "$SOURCE_HTML" "$WOFF2_FILE" <<'PY'
import base64
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"src:url\(data:font/woff2;base64,([^\)]+)\)", source)
if not match:
    raise SystemExit("Embedded Vazirmatn WOFF2 font was not found in src/app.html")
pathlib.Path(sys.argv[2]).write_bytes(base64.b64decode(match.group(1)))
PY

rm -f "$TTF_FILE"
woff2_decompress "$WOFF2_FILE"

if [[ ! -s "$TTF_FILE" ]]; then
  echo "Font conversion failed: $TTF_FILE was not generated" >&2
  exit 1
fi

python3 - "$PUBSPEC" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
block = """  fonts:\n    - family: Vazirmatn\n      fonts:\n        - asset: assets/fonts/vazirmatn/Vazirmatn-Variable.ttf\n"""
if "family: Vazirmatn" not in text:
    marker = "  generate: true\n"
    if marker not in text:
        raise SystemExit("flutter.generate marker was not found in pubspec.yaml")
    text = text.replace(marker, marker + block)
    path.write_text(text, encoding="utf-8")
PY

rm -f "$WOFF2_FILE"
echo "Prepared original Vazirmatn font: $TTF_FILE"
