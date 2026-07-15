#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""داشبورد شخصی — desktop wrapper.

Loads app.html in a WebKit view and persists all app data to
~/.local/share/dashboard-shakhsi/data.json (written atomically on
every change). File exports are saved straight into ~/Downloads.
"""
import json
import os
import re
import sys
import time

import gi

gi.require_version("Gtk", "3.0")
try:
    gi.require_version("WebKit2", "4.1")
except ValueError:
    gi.require_version("WebKit2", "4.0")
from gi.repository import Gtk, GLib, Gio, WebKit2  # noqa: E402

APP_ID = "org.local.DashboardShakhsi"
APP_DIR = os.path.dirname(os.path.abspath(__file__))
HTML_FILE = os.path.join(APP_DIR, "app.html")

DATA_DIR = os.path.join(
    GLib.get_user_data_dir() or os.path.expanduser("~/.local/share"),
    "dashboard-shakhsi",
)
DATA_FILE = os.path.join(DATA_DIR, "data.json")
WEBKIT_DIR = os.path.join(DATA_DIR, "webkit")
CACHE_DIR = os.path.join(
    GLib.get_user_cache_dir() or os.path.expanduser("~/.cache"),
    "dashboard-shakhsi",
)


def load_data():
    """Read saved key/value data; quarantine the file if it's corrupt."""
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


class DashboardApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id=APP_ID, flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        self.window = None
        self.webview = None

    # single instance: a second launch just focuses the open window
    def do_activate(self):
        if self.window is not None:
            self.window.present()
            return
        self._build_window()

    def _build_window(self):
        data = load_data()

        os.makedirs(WEBKIT_DIR, exist_ok=True)
        os.makedirs(CACHE_DIR, exist_ok=True)
        manager = WebKit2.WebsiteDataManager(
            base_data_directory=WEBKIT_DIR, base_cache_directory=CACHE_DIR
        )
        context = WebKit2.WebContext.new_with_website_data_manager(manager)

        ucm = WebKit2.UserContentManager()
        payload = json.dumps(json.dumps(data, ensure_ascii=False))
        boot = "window.__NATIVE_DATA__=JSON.parse(%s);" % payload
        ucm.add_script(
            WebKit2.UserScript(
                boot,
                WebKit2.UserContentInjectedFrames.TOP_FRAME,
                WebKit2.UserScriptInjectionTime.START,
                None,
                None,
            )
        )
        ucm.register_script_message_handler("saveData")
        ucm.connect("script-message-received::saveData", self.on_save_data)
        ucm.register_script_message_handler("saveFile")
        ucm.connect("script-message-received::saveFile", self.on_save_file)

        self.webview = WebKit2.WebView(
            web_context=context, user_content_manager=ucm
        )
        settings = self.webview.get_settings()
        settings.set_enable_javascript(True)
        settings.set_allow_file_access_from_file_urls(True)
        settings.set_enable_developer_extras("--devtools" in sys.argv)
        try:
            settings.set_enable_smooth_scrolling(True)
        except Exception:
            pass

        window = Gtk.ApplicationWindow(application=self)
        window.set_title("داشبورد شخصی")
        window.set_default_size(1180, 780)
        window.set_icon_name("dashboard-shakhsi")
        window.add(self.webview)
        self.window = window

        self.webview.load_uri(GLib.filename_to_uri(HTML_FILE, None))
        window.show_all()

    @staticmethod
    def _message_string(result):
        try:
            return result.get_js_value().to_string()
        except Exception:
            return None

    def on_save_data(self, _ucm, result):
        raw = self._message_string(result)
        if not raw:
            return
        try:
            data = json.loads(raw)
            if not isinstance(data, dict):
                return
        except Exception:
            return
        try:
            write_text_atomic(
                DATA_FILE, json.dumps(data, ensure_ascii=False, indent=1)
            )
        except Exception as exc:
            print("save failed:", exc, file=sys.stderr)

    def on_save_file(self, _ucm, result):
        raw = self._message_string(result)
        if not raw:
            return
        try:
            obj = json.loads(raw)
            name = safe_filename(obj.get("name"))
            content = str(obj.get("content", ""))
        except Exception:
            return
        folder = GLib.get_user_special_dir(
            GLib.UserDirectory.DIRECTORY_DOWNLOAD
        ) or os.path.expanduser("~/Downloads")
        try:
            os.makedirs(folder, exist_ok=True)
            path = unique_path(folder, name)
            write_text_atomic(path, content)
            self._notify_page(
                "فایل در پوشه دانلود ذخیره شد: " + os.path.basename(path)
            )
        except Exception as exc:
            print("file save failed:", exc, file=sys.stderr)
            self._notify_page("ذخیره فایل ناموفق بود")

    def _notify_page(self, message):
        if not self.webview:
            return
        js = "window.__toast&&window.__toast(%s);" % json.dumps(
            message, ensure_ascii=False
        )
        try:
            self.webview.run_javascript(js, None, None)
        except Exception:
            try:
                self.webview.evaluate_javascript(js, -1, None, None, None)
            except Exception:
                pass


def main():
    GLib.set_prgname("dashboard-shakhsi")
    GLib.set_application_name("داشبورد شخصی")
    app = DashboardApp()
    return app.run([a for a in sys.argv if a != "--devtools"])


if __name__ == "__main__":
    sys.exit(main())
