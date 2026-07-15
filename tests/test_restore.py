#!/usr/bin/env python3
"""Launch the app again (after test_save.py) and verify the saved
task is restored and actually rendered in the task list."""
import importlib.util
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location(
    "main", os.path.join(ROOT, "src", "main.py")
)
main = importlib.util.module_from_spec(spec)
spec.loader.exec_module(main)

from gi.repository import GLib, WebKit2  # noqa: E402

results = {"ui": None, "ok": False}


class TestApp(main.DashboardApp):
    def _build_window(self):
        super()._build_window()
        self.webview.connect("load-changed", self._on_load)

    def _on_load(self, wv, event):
        if event != WebKit2.LoadEvent.FINISHED:
            return
        GLib.timeout_add(1200, self._query_ui)  # let the app render

    def _query_ui(self):
        self.webview.run_javascript(
            "JSON.stringify({items:document.querySelectorAll('#list li').length,"
            "txt:(document.querySelector('#list li .txt')||{}).textContent||''})",
            None,
            self._got_ui,
        )
        return False

    def _got_ui(self, wv, res):
        try:
            raw = wv.run_javascript_finish(res).get_js_value().to_string()
            results["ui"] = raw
            parsed = json.loads(raw)
            results["ok"] = parsed.get("items") == 1 and parsed.get("txt") == "تست"
        except Exception as exc:
            results["ui"] = "ERR " + str(exc)
        self.quit()


app = TestApp()
GLib.timeout_add_seconds(30, app.quit)
app.run([])
print("test_restore:", json.dumps(results, ensure_ascii=False))
sys.exit(0 if results["ok"] else 1)
