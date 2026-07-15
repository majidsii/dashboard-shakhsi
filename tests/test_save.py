#!/usr/bin/env python3
"""Launch the app, push a task through the native save bridge,
then verify it landed in data.json on disk."""
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

results = {"loaded": False, "env": None, "saved": False}


class TestApp(main.DashboardApp):
    def _build_window(self):
        super()._build_window()
        self.webview.connect("load-changed", self._on_load)

    def _on_load(self, wv, event):
        if event != WebKit2.LoadEvent.FINISHED:
            return
        results["loaded"] = True
        wv.run_javascript(
            "JSON.stringify({native:!!window.__NATIVE_DATA__,"
            "toast:typeof window.__toast})",
            None,
            self._got_env,
        )

    def _got_env(self, wv, res):
        try:
            value = wv.run_javascript_finish(res).get_js_value()
            results["env"] = value.to_string()
        except Exception as exc:  # pragma: no cover
            results["env"] = "ERR " + str(exc)
        wv.run_javascript(
            "window.__NATIVE_DATA__['tasklist:v1']=JSON.stringify("
            "[{id:'t1',text:'تست',done:false,priority:2,created:Date.now()}]);"
            "window.webkit.messageHandlers.saveData.postMessage("
            "JSON.stringify(window.__NATIVE_DATA__));",
            None,
            None,
        )
        GLib.timeout_add(1500, self._check_disk)

    def _check_disk(self):
        try:
            with open(main.DATA_FILE, encoding="utf-8") as fh:
                data = json.load(fh)
            results["saved"] = (
                "tasklist:v1" in data and "تست" in data["tasklist:v1"]
            )
        except Exception as exc:
            results["saved"] = "ERR " + str(exc)
        self.quit()
        return False


app = TestApp()
GLib.timeout_add_seconds(30, app.quit)
app.run([])
print("test_save:", json.dumps(results, ensure_ascii=False))
sys.exit(0 if results["loaded"] and results["saved"] is True else 1)
