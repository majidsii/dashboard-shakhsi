#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = (
    root
    / "lib/features/dashboard/presentation/widgets/"
    "finance_panel.dart"
)

source = path.read_text(encoding="utf-8")

old = """                  Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),"""

new = """                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),"""

if new in source:
    print("Finance card header overflow hotfix is already applied.")
elif old in source:
    path.write_text(
        source.replace(old, new, 1),
        encoding="utf-8",
    )
    print("Finance card header overflow hotfix applied.")
else:
    raise SystemExit(
        "Expected _FinanceCard title block was not found. "
        "No file was changed."
    )
