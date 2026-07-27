#!/usr/bin/env python3
from pathlib import Path

app_dir = Path(__file__).resolve().parents[1]
source_html = (app_dir.parent / "src" / "app.html").read_text(encoding="utf-8")
tokens = (app_dir / "lib" / "app" / "theme" / "original_design_tokens.dart").read_text(encoding="utf-8")
screen = (app_dir / "lib" / "features" / "dashboard" / "presentation" / "dashboard_screen.dart").read_text(encoding="utf-8")

contracts = {
    "original max width": (".app{max-width:780px", "contentMaxWidth = 780"),
    "original blur": ("backdrop-filter:blur(28px)", "glassBlurSigma = 28"),
    "original glass radius": ("border-radius:26px", "glassRadius = 26"),
    "original card radius": ("border-radius:28px", "cardRadius = 28"),
    "original field radius": ("border-radius:16px", "fieldRadius = 16"),
    "original tasks tab": (">کارها<", "'کارها'"),
    "original finance tab": (">مالی<", "'مالی'"),
}

for name, (html_marker, dart_marker) in contracts.items():
    if html_marker not in source_html:
        raise SystemExit(f"Missing original source marker for {name}: {html_marker}")
    target = tokens if "radius" in name or "width" in name or "blur" in name else screen
    if dart_marker not in target:
        raise SystemExit(f"Flutter port does not preserve {name}: {dart_marker}")

for forbidden in ("NavigationRail", "NavigationDrawer", "Sidebar", "BottomNavigationBar"):
    if forbidden in screen:
        raise SystemExit(f"Rejected redesign element found: {forbidden}")

print("Original visual contract verified.")
