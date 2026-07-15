#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""داشبورد شخصی — cross-platform wrapper (Windows / macOS / Linux).

Uses pywebview (WebView2 on Windows, WKWebView on macOS, WebKitGTK on
Linux). Saved data is injected into the page before it loads and every
change is written atomically to a per-OS data directory:

  Windows : %APPDATA%\\dashboard-shakhsi\\data.json
  macOS   : ~/Library/Application Support/dashboard-shakhsi/data.json
  Linux   : ~/.local/share/dashboard-shakhsi/data.json  (same as the .deb)

File exports go to ~/Downloads. Debug: run with --devtools
"""
import json
import os
import re
import sys
import time

import webview

APP_NAME = "dashboard-shakhsi"
APP_TITLE = "داشبورد شخصی"


def resource_path(name):
    """Locate bundled files both in source and inside PyInstaller onefile."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, name)


def data_dir():
    if sys.platform == "win32":
        root = os.environ.get("APPDATA") or os.path.expanduser("~")
        return os.path.join(root, APP_NAME)
    if sys.platform == "darwin":
        return os.path.expanduser(
            "~/Library/Application Support/" + APP_NAME
        )
    root = os.environ.get("XDG_DATA_HOME") or os.path.expanduser(
        "~/.local/share"
    )
    return os.path.join(root, APP_NAME)


DATA_FILE = os.path.join(data_dir(), "data.json")


def load_data():
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, dict):
            return {str(k): str(v) for k, v in data.items()}
    except FileNotFoundError:
        pass
    except Exception:
        try:
            stamp = time.strftime("%Y%m%d-%H%M%S")
            os.replace(DATA_FILE, DATA_FILE + ".corrupt-" + stamp)
        except Exception:
            pass
    return {}


def write_text_atomic(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)


def safe_filename(name):
    name = os.path.basename(str(name or "file.txt"))
    name = re.sub(r'[\\/:*?"<>|\x00-\x1f]', "_", name).strip()
    return (name or "file.txt")[:120]


def unique_path(folder, name):
    base, ext = os.path.splitext(name)
    path = os.path.join(folder, name)
    i = 2
    while os.path.exists(path):
        path = os.path.join(folder, "%s (%d)%s" % (base, i, ext))
        i += 1
    return path


class Api:
    """Exposed to the page as window.pywebview.api"""

    def save_data(self, payload):
        try:
            data = json.loads(payload)
            if not isinstance(data, dict):
                return False
            write_text_atomic(
                DATA_FILE, json.dumps(data, ensure_ascii=False, indent=1)
            )
            return True
        except Exception as exc:
            print("save failed:", exc, file=sys.stderr)
            return False

    def save_file(self, name, content):
        folder = os.path.join(os.path.expanduser("~"), "Downloads")
        try:
            os.makedirs(folder, exist_ok=True)
            path = unique_path(folder, safe_filename(name))
            write_text_atomic(path, str(content))
            return os.path.basename(path)
        except Exception as exc:
            print("file save failed:", exc, file=sys.stderr)
            return None


def build_html():
    with open(resource_path("app.html"), encoding="utf-8") as fh:
        html = fh.read()
    payload = json.dumps(json.dumps(load_data(), ensure_ascii=False))
    boot = (
        "<script>window.__NATIVE_DATA__=JSON.parse(%s);</script>" % payload
    )
    anchor = '<meta charset="UTF-8">'
    if anchor in html:
        return html.replace(anchor, anchor + boot, 1)
    return html.replace("<head>", "<head>" + boot, 1)


def main():
    debug = "--devtools" in sys.argv
    webview.create_window(
        APP_TITLE,
        html=build_html(),
        js_api=Api(),
        width=1180,
        height=780,
        min_size=(760, 560),
    )
    webview.start(debug=debug)


if __name__ == "__main__":
    main()
