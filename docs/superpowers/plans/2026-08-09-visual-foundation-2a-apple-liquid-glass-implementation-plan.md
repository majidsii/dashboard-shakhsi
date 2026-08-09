# Visual Foundation 2.A — Apple Liquid Glass System Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current visible Flutter UI foundation with a source-locked Apple Liquid Glass system: Android/mobile reproduces the supplied iOS 27 references and Windows/Linux desktop reproduces the supplied macOS 27 references, while preserving all existing business behavior.

**Architecture:** Keep the existing router, Riverpod, Drift, localization, notification and domain/data boundaries intact. Introduce a new `lib/app/apple_visual/` visual foundation that owns source-derived tokens, platform-family resolution, typography, materials, control states, Liquid Glass rendering and shared Apple controls. `MaterialApp.router` may remain temporarily as non-visible host infrastructure, but no migrated feature may obtain visible styling from Material defaults; feature UI must consume Apple semantic primitives. Migrate shell → shared controls → feature screens, with source-derived golden fixtures and a semantic guard preventing silent fallback to Material/Fluent/native styling.

**Tech Stack:** Flutter 3.44.6 stable, Dart 3.12.2, Riverpod 2.6.1, GoRouter 17.3.0, Flutter test/goldens, CustomPainter/BackdropFilter/FragmentProgram as required by source fidelity, Python 3 for deterministic Sketch extraction and semantic verification.

## Global Constraints

- Source of truth: `docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md`.
- Frozen contract: `docs/superpowers/specs/2026-08-09-apple-liquid-glass-fidelity-contract.md`.
- Canonical design: `docs/superpowers/specs/2026-08-09-apple-liquid-glass-visual-system-design.md`.
- Android/mobile = supplied iOS 27 visual system **exactly**.
- Windows/Linux desktop = supplied macOS 27 visual system **exactly**.
- No Material, Fluent, Windows-native or Linux-native visible fallback.
- “Apple-like”, “similar”, “close enough” and hand-tuned substitutions are not accepted.
- If a source value is unavailable, it remains unresolved; do not guess it.
- If a renderer cannot match a source effect, stop that fidelity gate and document the measured deviation for explicit user approval.
- Preserve Persian RTL behavior and existing feature semantics.
- Task 2.8 remains immutable unless a verified defect exists.
- Task 2.9 remains blocked until Visual Foundation 2.A is implemented, verified, checkpointed and pushed.
- No database schema change is required by this plan.
- Do not run `flutter upgrade`.
- Existing full-suite behavior is a regression contract.
- Existing external Sketch binaries are not copied into the repository; checked-in generated reference data must record the exact source SHA-256.
- Never bundle or redistribute Apple font binaries as part of this work unless the user supplies a legally usable local source and explicitly approves that packaging boundary.

---

## Audit Baseline

Fresh repo audit at documentation-lock HEAD `9ca00ee` established:

- app root is `MaterialApp.router`;
- visible theme root is `OriginalTheme` / `OriginalPalette`;
- current theme uses `ThemeData`, `ColorScheme.fromSeed`, `InputDecorationTheme` and `Vazirmatn`;
- current custom glass is `OriginalGlass`, based on `BackdropFilter`, blur, saturation matrix, gradients, rim painter and custom shadows;
- Material-specific visible controls remain in template dialogs/pickers, timers, calendar and some task flows;
- current responsive behavior is width-driven with `LayoutBuilder`; there is no dedicated visual platform-family resolver;
- no desktop window/titlebar integration package or native window-chrome abstraction was found;
- no golden/screenshot fidelity infrastructure was found;
- current production contains at least:
  - 87 `Color(0x...)` literals across 5 files;
  - 29 `Colors.*` uses across 13 files;
  - 118 `TextStyle(` occurrences across 17 files;
  - 120 `fontSize:` occurrences across 16 files;
  - 49 `BorderRadius` occurrences across 13 files;
  - 28 `BoxShadow` occurrences across 5 files;
  - one `BackdropFilter` in the current glass implementation;
- major migration hotspots include:
  - `tasks_panel.dart` ~1850 lines;
  - `finance_panel.dart` ~1590 lines;
  - `task_kanban_board.dart` ~776 lines;
  - `task_calendar_board.dart` ~719 lines;
  - `task_jalali_date_time_field.dart` ~659 lines;
  - `finance_charts.dart` ~600 lines;
  - `task_timer_panel.dart` ~513 lines.

The migration must therefore centralize visual semantics before touching those large feature files.

---

## Planned File Structure

### Source extraction / evidence

- Create: `tool/apple_ui_kit_reference_extractor.py`
- Create: `tool/verify_visual_foundation_2a_sources.py`
- Create: `docs/superpowers/references/generated/apple_ui_kit_reference.json`
- Create: `docs/superpowers/references/generated/apple_ui_kit_component_map.md`
- Create: `test/app/apple_visual/apple_reference_manifest_test.dart`

Responsibilities:

- verify exact SHA-256 before extraction;
- unzip/read Sketch JSON deterministically;
- extract shared swatches, text styles, layer styles and measurable component geometry;
- preserve source page/component/state identifiers;
- never silently synthesize a missing value;
- generate stable JSON ordered deterministically;
- produce a human-readable component map used by implementation/review.

### Core visual foundation

- Create: `lib/app/apple_visual/foundation/apple_visual_family.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_platform_resolver.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_theme.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_tokens.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_typography.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_metrics.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_materials.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_motion.dart`
- Create: `lib/app/apple_visual/foundation/apple_visual_state.dart`
- Create: `lib/app/apple_visual/generated/apple_source_reference.g.dart`

Responsibilities:

- map runtime platform to `ios27` or `macos27`;
- expose source-derived semantic tokens only;
- separate light/dark;
- separate iOS/macOS;
- expose component state variants;
- keep generated source data separate from ergonomic app-facing semantic APIs.

### Rendering primitives

- Create: `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
- Create: `lib/app/apple_visual/widgets/apple_surface.dart`
- Create: `lib/app/apple_visual/widgets/apple_pressable.dart`
- Create: `lib/app/apple_visual/widgets/apple_icon.dart`
- Create: `lib/app/apple_visual/widgets/apple_text.dart`
- Create: `lib/app/apple_visual/widgets/apple_separator.dart`

Responsibilities:

- exact source-calibrated glass/material composition;
- platform/state/brightness-aware rendering;
- no feature-local blur/rim/shadow math;
- pointer/press/focus handling;
- source-locked icon/vector abstraction.

### Shared controls

- Create: `lib/app/apple_visual/controls/apple_button.dart`
- Create: `lib/app/apple_visual/controls/apple_icon_button.dart`
- Create: `lib/app/apple_visual/controls/apple_text_field.dart`
- Create: `lib/app/apple_visual/controls/apple_search_field.dart`
- Create: `lib/app/apple_visual/controls/apple_segmented_control.dart`
- Create: `lib/app/apple_visual/controls/apple_toggle.dart`
- Create: `lib/app/apple_visual/controls/apple_menu.dart`
- Create: `lib/app/apple_visual/controls/apple_list_row.dart`
- Create: `lib/app/apple_visual/controls/apple_dialog.dart`
- Create: `lib/app/apple_visual/controls/apple_popover.dart`
- Create: `lib/app/apple_visual/controls/apple_sheet.dart`
- Create: `lib/app/apple_visual/controls/apple_transient_feedback.dart`

### App shell

- Create: `lib/app/apple_visual/shell/apple_app_background.dart`
- Create: `lib/app/apple_visual/shell/apple_dashboard_shell.dart`
- Create: `lib/app/apple_visual/shell/apple_dashboard_toolbar.dart`
- Modify: `lib/app/bootstrap/app_bootstrap.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`

### Fidelity testing

- Create: `test/support/apple_visual_test_host.dart`
- Create: `test/support/apple_golden.dart`
- Create: `test/app/apple_visual/apple_platform_resolver_test.dart`
- Create: `test/app/apple_visual/apple_tokens_test.dart`
- Create: `test/app/apple_visual/apple_typography_test.dart`
- Create: `test/app/apple_visual/apple_liquid_glass_test.dart`
- Create: `test/app/apple_visual/apple_controls_test.dart`
- Create: `test/app/apple_visual/apple_shell_test.dart`
- Create golden directories:
  - `test/goldens/apple/ios27/light/`
  - `test/goldens/apple/ios27/dark/`
  - `test/goldens/apple/macos27/light/`
  - `test/goldens/apple/macos27/dark/`

### Migration guard

- Create: `tool/verify_visual_foundation_2a_no_visual_fallback.py`
- Create: `tool/verify_visual_foundation_2a_green.py`

The no-fallback verifier must distinguish Material as host/infrastructure from Material as visible styling. It must reject visible fallback widgets/tokens in migrated production paths, without requiring a pointless rewrite of GoRouter/localization infrastructure.

---

# Gate A — Reproducible Source Extraction Before Visual Code

### Task 1: Build deterministic Sketch reference extraction

**Files:**
- Create: `tool/apple_ui_kit_reference_extractor.py`
- Create: `tool/verify_visual_foundation_2a_sources.py`
- Create: `docs/superpowers/references/generated/apple_ui_kit_reference.json`
- Create: `docs/superpowers/references/generated/apple_ui_kit_component_map.md`
- Test: `test/app/apple_visual/apple_reference_manifest_test.dart`
- Modify: `docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md` only to link generated outputs; do not change frozen hashes.

**Interfaces:**
- Consumes:
  - macOS Sketch SHA `8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`
  - iOS Sketch SHA `5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`
  - macOS asset ZIP SHA `4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31`
- Produces:
  - deterministic source-reference JSON;
  - component/state/source-page map;
  - source verifier that fails on hash drift or unresolved required extraction schema.

- [ ] **Step 1: Write RED extraction verifier fixture**

Create tests around a tiny synthetic Sketch ZIP fixture generated inside the test script, not by committing Apple binary content.

Required assertions:

```python
assert extracted["source"]["sha256"] == expected_sha
assert extracted["swatches"] == sorted(extracted["swatches"], key=lambda x: x["sourceId"])
assert extracted["textStyles"][0]["fontFamily"] is not None
assert "pageName" in extracted["componentLayers"][0]
assert "stateName" in extracted["componentLayers"][0]
```

The extractor must represent missing source values as `null` plus a source path; it must never invent defaults.

- [ ] **Step 2: Run extractor tests and confirm RED**

Run:

```bash
python3 tool/verify_visual_foundation_2a_sources.py --self-test
```

Expected: FAIL because extractor/output contract does not exist.

- [ ] **Step 3: Implement exact hash verification and Sketch JSON traversal**

Required core API:

```python
@dataclass(frozen=True)
class SourceFile:
    path: Path
    expected_sha256: str

def verify_sha256(source: SourceFile) -> None: ...

def extract_sketch_reference(source: SourceFile) -> dict[str, object]: ...

def write_deterministic_json(value: object, output: Path) -> None: ...
```

Extraction must include:

- document metadata;
- pages/page names;
- shared swatches;
- shared layer styles;
- shared text styles;
- referenced font family/PostScript names;
- layer frames;
- radii;
- fills/gradients;
- borders;
- shadows;
- blur data;
- opacity;
- symbol/component/state labels that can be resolved from names;
- source IDs for traceability.

- [ ] **Step 4: Run against exact user-supplied binaries**

Command form:

```bash
python3 tool/apple_ui_kit_reference_extractor.py \
  --ios-sketch "/absolute/path/Apple iOS 27 UI Kit.sketch" \
  --macos-sketch "/absolute/path/Apple macOS 27 UI Kit(1).sketch" \
  --macos-assets "/absolute/path/apple-macos-27-ui-kit_assets_2026-06-23_v12(1).zip" \
  --output docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --component-map docs/superpowers/references/generated/apple_ui_kit_component_map.md
```

Expected: hashes match manifest before any output is written.

- [ ] **Step 5: Add manifest-focused Flutter test**

Test must parse the generated JSON and assert:

```dart
expect(reference.ios.sourceSha256, '<frozen iOS SHA>');
expect(reference.macos.sourceSha256, '<frozen macOS SHA>');
expect(reference.ios.pageCount, 34);
expect(reference.macos.pageCount, 37);
```

Also assert required source families exist: colors, materials, buttons, text fields, segmented controls, dialogs/alerts, popovers/sheets, and relevant navigation chrome.

- [ ] **Step 6: Run Gate A verification**

```bash
python3 tool/verify_visual_foundation_2a_sources.py
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_reference_manifest_test.dart
git diff --check
```

- [ ] **Step 7: Gate A review**

Do not proceed if any of these are unresolved:

1. exact source hashes;
2. source text-style font family/PostScript names;
3. required component states;
4. required Liquid Glass layer recipe data;
5. icon/vector source strategy.

**Typography hard stop:** if the supplied sources do not define a usable Persian-capable font path for Windows/Linux/Android, record this as an unresolved fidelity blocker. Do not silently retain Vazirmatn and call the result exact.

**Icon hard stop:** if the supplied sources do not provide redistributable/vector-resolvable equivalents for the symbols needed by the app, do not silently retain Material `Icons.*` in a migrated component.

- [ ] **Step 8: Commit Gate A**

```bash
git add tool/apple_ui_kit_reference_extractor.py \
  tool/verify_visual_foundation_2a_sources.py \
  docs/superpowers/references/generated \
  docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md \
  test/app/apple_visual/apple_reference_manifest_test.dart

git commit -m "test: lock apple ui kit reference extraction"
```

---

# Gate B — Platform Family, Source Tokens, Typography and Metrics

### Task 2: Introduce the Apple visual foundation contract

**Files:**
- Create: all `lib/app/apple_visual/foundation/*` files listed above
- Create: `lib/app/apple_visual/generated/apple_source_reference.g.dart`
- Test:
  - `test/app/apple_visual/apple_platform_resolver_test.dart`
  - `test/app/apple_visual/apple_tokens_test.dart`
  - `test/app/apple_visual/apple_typography_test.dart`

**Interfaces:**
- Produces:

```dart
enum AppleVisualFamily { ios27, macos27 }

final class AppleVisualPlatformResolver {
  const AppleVisualPlatformResolver();

  AppleVisualFamily resolve(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android || TargetPlatform.iOS => AppleVisualFamily.ios27,
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => AppleVisualFamily.macos27,
      TargetPlatform.fuchsia => throw UnsupportedError(...),
    };
  }
}
```

And source-facing theme access:

```dart
final class AppleVisualThemeData extends ThemeExtension<AppleVisualThemeData> {
  final AppleVisualFamily family;
  final Brightness brightness;
  final AppleColorTokens colors;
  final AppleTypographyTokens typography;
  final AppleMetricTokens metrics;
  final AppleMaterialTokens materials;
  final AppleMotionTokens motion;
}

AppleVisualThemeData appleVisualThemeOf(BuildContext context);
```

- [ ] **Step 1: RED platform resolver tests**

Test exact mapping:

```dart
expect(resolve(TargetPlatform.android), AppleVisualFamily.ios27);
expect(resolve(TargetPlatform.iOS), AppleVisualFamily.ios27);
expect(resolve(TargetPlatform.windows), AppleVisualFamily.macos27);
expect(resolve(TargetPlatform.linux), AppleVisualFamily.macos27);
expect(resolve(TargetPlatform.macOS), AppleVisualFamily.macos27);
```

No width-based family switching.

- [ ] **Step 2: RED token source tests**

Every runtime token must carry source provenance or map to a generated source token.

Examples:

```dart
expect(theme.colors.primaryLabel.sourcePage, 'Colors');
expect(theme.typography.body.sourceStyleId, isNotEmpty);
expect(theme.materials.primaryGlass.sourceLayerStyleIds, isNotEmpty);
```

- [ ] **Step 3: Implement generated → semantic mapping**

Do not type source values directly into feature-facing classes.

Generated source data should look conceptually like:

```dart
abstract final class AppleSourceReference {
  static const ios27 = AppleGeneratedFamilyReference(...);
  static const macos27 = AppleGeneratedFamilyReference(...);
}
```

`AppleVisualThemeData` maps source IDs into semantic roles used by the app.

- [ ] **Step 4: Resolve typography fidelity**

Tests must fail if a runtime typography role silently falls back to `Vazirmatn` while the exact source family is unresolved.

Allow an explicit unresolved state during Gate B:

```dart
sealed class AppleFontResolution {}

final class AppleResolvedFont extends AppleFontResolution {
  final String family;
  final String sourcePostScriptName;
}

final class AppleUnresolvedFont extends AppleFontResolution {
  final String reason;
}
```

Gate B cannot be marked complete while a production-visible required typography role is unresolved.

- [ ] **Step 5: Keep Material host neutral**

Modify `OriginalTheme` only after Apple theme data is available. Do not yet delete it.

`ThemeData` may host brightness/localization mechanics, but visible palette and controls must not read `ColorScheme.fromSeed`.

Add a test that Apple theme data is installed in light/dark app roots.

- [ ] **Step 6: Run Gate B**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_platform_resolver_test.dart \
  test/app/apple_visual/apple_tokens_test.dart \
  test/app/apple_visual/apple_typography_test.dart
/home/shabin/develop/flutter/bin/flutter analyze
git diff --check
```

- [ ] **Step 7: Commit Gate B**

```bash
git add lib/app/apple_visual/foundation \
  lib/app/apple_visual/generated \
  test/app/apple_visual

git commit -m "feat: add source-locked apple visual tokens"
```

---

# Gate C — Liquid Glass and Low-Level Rendering Primitives

### Task 3: Replace ad-hoc glass math with source-locked material rendering

**Files:**
- Create:
  - `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
  - `lib/app/apple_visual/widgets/apple_surface.dart`
  - `lib/app/apple_visual/widgets/apple_pressable.dart`
  - `lib/app/apple_visual/widgets/apple_text.dart`
  - `lib/app/apple_visual/widgets/apple_separator.dart`
- Potentially create: `shaders/apple_liquid_glass.frag` only if extracted source fidelity cannot be reached using composited Flutter primitives.
- Test:
  - `test/app/apple_visual/apple_liquid_glass_test.dart`
  - golden fixtures under all four family/brightness directories.

**Interfaces:**

```dart
enum AppleGlassRole {
  smallControl,
  tintedSmallControl,
  mediumSurface,
  largeSurface,
  overGlassControl,
}

final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.role,
    required this.child,
    this.state = AppleControlState.idle,
    super.key,
  });
}
```

- [ ] **Step 1: RED source-value tests**

For each required glass role, assert the renderer consumes only extracted material tokens.

No default parameters like the current `blurSigma = 28` are allowed unless that exact value is source-derived and provenance-backed.

- [ ] **Step 2: RED light/dark + iOS/macOS goldens**

At minimum:

```text
ios27/light/small-control.png
ios27/dark/small-control.png
ios27/light/medium-surface.png
ios27/dark/medium-surface.png
macos27/light/small-control.png
macos27/dark/small-control.png
macos27/light/medium-surface.png
macos27/dark/medium-surface.png
macos27/light/over-glass-control.png
macos27/dark/over-glass-control.png
```

Each golden test must use fixed surface size, DPR and controlled background.

- [ ] **Step 3: Implement minimum exact renderer**

Start with standard Flutter composition only if it matches the source:

- clipped backdrop;
- source blur;
- source fill/tint;
- source gradients;
- source border/rim;
- source shadow;
- source highlight;
- source state overlays.

If source comparison proves standard composition cannot reproduce a required effect, create the fragment shader as a renderer implementation detail.

Do not add a shader preemptively.

- [ ] **Step 4: Add platform-specific renderer-deviation report hook**

Create a test-visible structure:

```dart
final class AppleRendererDeviation {
  final AppleVisualFamily family;
  final String component;
  final String platform;
  final String reason;
  final double? measuredDelta;
}
```

Production default must contain zero accepted deviations.

- [ ] **Step 5: Compare against source exports**

No golden is approved from the app’s own current rendering. Reference goldens must be exported/derived from the locked Apple source at controlled dimensions.

- [ ] **Step 6: Run Gate C**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_test.dart
/home/shabin/develop/flutter/bin/flutter analyze
git diff --check
```

- [ ] **Step 7: Commit Gate C**

```bash
git add lib/app/apple_visual/widgets \
  test/app/apple_visual/apple_liquid_glass_test.dart \
  test/goldens/apple \
  shaders

git commit -m "feat: add source-locked apple liquid glass rendering"
```

---

# Gate D — Exact Shared Controls and Visual Fallback Guard

### Task 4: Build Apple controls before migrating feature screens

**Files:**
- Create all `lib/app/apple_visual/controls/*` files listed above.
- Test: `test/app/apple_visual/apple_controls_test.dart`
- Create: `tool/verify_visual_foundation_2a_no_visual_fallback.py`

**Interfaces:**

Every control consumes semantic source roles.

Example:

```dart
enum AppleButtonRole { primary, secondary, destructive, toolbar, icon }

final class AppleButton extends StatelessWidget {
  const AppleButton({
    required this.role,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    super.key,
  });
}
```

State is resolved centrally:

```dart
enum AppleControlState { idle, hovered, pressed, selected, disabled, focused }
```

- [ ] **Step 1: RED component-state tests**

For each control family required by current production UI, test applicable states.

Desktop minimum:

- idle;
- hover;
- pressed/clicked;
- focused;
- selected where applicable;
- disabled.

Mobile minimum:

- idle;
- pressed;
- focused/editing where applicable;
- selected;
- disabled.

- [ ] **Step 2: RED component goldens**

Cover iOS/macOS and light/dark for:

- button;
- icon button;
- text field;
- search field;
- segmented control;
- toggle;
- list row;
- dialog;
- menu/popover;
- sheet where applicable.

- [ ] **Step 3: Implement controls without visible Material defaults**

Using `package:flutter/material.dart` for core types does not itself violate the contract.

The following visible fallback behavior does:

- `FilledButton` / `ElevatedButton` / `OutlinedButton` / `TextButton` as final visual controls;
- Material `Card`;
- Material `ListTile`;
- Material `AlertDialog` as final visual shell;
- Material `Chip`;
- Material adaptive `Switch` as final visual control;
- `ColorScheme`-derived visible colors;
- Material ink/splash state;
- Material Icons where the source-locked Apple icon strategy has been resolved.

- [ ] **Step 4: Implement no-fallback verifier**

The script must scan migrated paths and fail on forbidden visible fallback classes.

Initial allow-list may preserve not-yet-migrated feature files. The allow-list must shrink at every feature migration gate and be empty for the targeted presentation surface at exit.

- [ ] **Step 5: Run Gate D**

```bash
python3 tool/verify_visual_foundation_2a_no_visual_fallback.py
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_controls_test.dart
git diff --check
```

- [ ] **Step 6: Commit Gate D**

```bash
git add lib/app/apple_visual/controls \
  test/app/apple_visual/apple_controls_test.dart \
  tool/verify_visual_foundation_2a_no_visual_fallback.py

git commit -m "feat: add exact apple shared controls"
```

---

# Gate E — App Host and Dashboard Shell

### Task 5: Install Apple theme at the root and migrate visible shell

**Files:**
- Modify:
  - `lib/app/bootstrap/app_bootstrap.dart`
  - `lib/app/theme/theme_mode_controller.dart` only if needed for Apple appearance semantics
  - `lib/features/dashboard/presentation/dashboard_screen.dart`
- Create:
  - `lib/app/apple_visual/shell/apple_app_background.dart`
  - `lib/app/apple_visual/shell/apple_dashboard_shell.dart`
  - `lib/app/apple_visual/shell/apple_dashboard_toolbar.dart`
- Test:
  - `test/app/apple_visual/apple_shell_test.dart`
  - modify `test/app/bootstrap/app_bootstrap_test.dart`
  - modify `test/features/dashboard/original_dashboard_screen_test.dart`

**Interfaces:**

- `MaterialApp.router` remains only as router/localization/theme-mode host unless a concrete visual mismatch proves it must be replaced.
- All visible shell content is Apple-owned.
- Existing Tasks/Finance information architecture remains unchanged.
- Existing section switcher maps to the source segmented-control treatment rather than inventing a new navigation model.
- Persian RTL remains active.

- [ ] **Step 1: RED root-theme test**

Assert:

```dart
final apple = appleVisualThemeOf(context);
expect(apple.family, AppleVisualFamily.macos27); // Linux test host override
expect(find.byType(OriginalGlass), findsNothing);
```

in the migrated shell.

- [ ] **Step 2: RED desktop shell golden**

Fixed desktop target sizes at minimum:

- 1440×900 macOS-family light;
- 1440×900 macOS-family dark.

- [ ] **Step 3: RED mobile shell golden**

Fixed mobile target sizes at minimum:

- 390×844 iOS-family light;
- 390×844 iOS-family dark.

Do not infer Apple family from width. Test host explicitly overrides platform.

- [ ] **Step 4: Replace Aurora/Original shell visuals**

`AuroraBackground`, `_BrandIsland`, `_TopTabs`, `_ThemeIsland` and local glass decorations are migrated to Apple foundation primitives.

Do not delete old files yet if feature widgets still depend on them.

- [ ] **Step 5: Preserve interaction behavior**

Existing tests must still prove:

- theme toggle works;
- Tasks/Finance switching works;
- router remains ready;
- notification startup remains unaffected.

- [ ] **Step 6: Run Gate E**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/bootstrap/app_bootstrap_test.dart \
  test/app/apple_visual/apple_shell_test.dart \
  test/features/dashboard/original_dashboard_screen_test.dart
/home/shabin/develop/flutter/bin/flutter analyze
python3 tool/verify_visual_foundation_2a_no_visual_fallback.py
git diff --check
```

- [ ] **Step 7: Commit Gate E**

```bash
git add lib/app/bootstrap/app_bootstrap.dart \
  lib/app/apple_visual/shell \
  lib/features/dashboard/presentation/dashboard_screen.dart \
  test/app \
  test/features/dashboard/original_dashboard_screen_test.dart

git commit -m "feat: migrate dashboard shell to apple visual foundation"
```

---

# Gate F — Dashboard Feature Surfaces

### Task 6: Migrate Tasks and Finance dashboard panels without business changes

**Files:**
- Modify:
  - `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
  - `lib/features/dashboard/presentation/widgets/finance_panel.dart`
  - `lib/features/dashboard/presentation/widgets/finance_charts.dart`
- Tests:
  - all existing dashboard tests;
  - new targeted visual fixture tests:
    - `test/features/dashboard/tasks_panel_apple_visual_test.dart`
    - `test/features/dashboard/finance_panel_apple_visual_test.dart`

**Migration rule:**

Do not redesign domain behavior while touching these ~1850/~1590-line hotspots.

Visual extraction may introduce focused private/shared widgets if that reduces local styling duplication, but do not move business orchestration out of these files unless necessary for testability.

- [ ] **Step 1: RED no-fallback scan for Tasks panel**

Shrink verifier allow-list so `tasks_panel.dart` is required to have no forbidden visible Material fallback.

- [ ] **Step 2: Replace local visual magic numbers**

Map current:

- local `TextStyle`;
- hard-coded radii;
- hard-coded row/background colors;
- local shadows;
- hover visuals;
- filter pills;
- quick-entry controls;
- priority controls;
- list row surfaces;
- empty state surfaces;

to Apple semantic controls/tokens.

- [ ] **Step 3: Preserve behavior tests**

Run all existing Tasks panel tests before/after.

- [ ] **Step 4: RED/green Tasks panel visual fixture**

Cover:

- list;
- quick-entry;
- filter/selected state;
- active timer strip;
- light/dark;
- desktop/mobile reference family.

- [ ] **Step 5: Repeat for Finance panel/charts**

Charts may retain domain/chart geometry, but labels, legends, surfaces, tooltips and chrome must use Apple source tokens.

Do not force source UI-kit geometry onto chart data itself when the source has no such chart component; unresolved chart-specific styling must be derived only from approved semantic tokens, not invented “Apple-like” effects.

- [ ] **Step 6: Run Gate F**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/features/dashboard \
  test/app/apple_visual
python3 tool/verify_visual_foundation_2a_no_visual_fallback.py
/home/shabin/develop/flutter/bin/flutter analyze
git diff --check
```

- [ ] **Step 7: Commit Gate F**

```bash
git add lib/features/dashboard/presentation \
  test/features/dashboard \
  tool/verify_visual_foundation_2a_no_visual_fallback.py

git commit -m "feat: migrate dashboard panels to apple visual foundation"
```

---

# Gate G — Task Workflows, Dialogs, Calendar, Kanban, Templates and Timer

### Task 7: Migrate task presentation surfaces in coherent sub-gates

This task is intentionally split into reviewer-sized sub-gates because the audit found several large independent UI files.

## Gate G1 — Task Details

**Files:**
- Modify:
  - `task_details_dialog.dart`
  - `task_details_form.dart`
  - `task_duration_field.dart`
  - `task_jalali_date_time_field.dart`
  - `task_recurrence_field.dart`
  - `task_reminder_rules_field.dart`
- Existing tests under `test/features/tasks/presentation/task_details/`
- Add: `task_details_apple_visual_test.dart`

- [ ] RED no-fallback scan for Task Details.
- [ ] Replace dialog shell, fields, buttons, separators, toggles, date-time controls with Apple primitives.
- [ ] Preserve focus traversal, semantics, validation and draft behavior.
- [ ] Add desktop/mobile + light/dark visual fixtures.
- [ ] Run Task Details test subtree + analyzer + fallback verifier.
- [ ] Commit:

```bash
git commit -m "feat: migrate task details to apple visual foundation"
```

## Gate G2 — Templates

**Files:**
- Modify:
  - `task_template_picker.dart`
  - `task_template_manager_dialog.dart`
  - `task_template_editor_dialog.dart`
- Existing template tests
- Add: `task_templates_apple_visual_test.dart`

- [ ] Remove final visual use of Material `Card`, `ListTile`, `Chip`, `AlertDialog`, `FilledButton`, `OutlinedButton`, `TextButton`.
- [ ] Preserve system/custom lifecycle behavior exactly.
- [ ] Add family/brightness visual fixtures.
- [ ] Run Task 2.8 template integration tests and Task 2.8 complete verifier.
- [ ] Commit:

```bash
git commit -m "feat: migrate task templates to apple visual foundation"
```

## Gate G3 — Timer

**Files:**
- Modify:
  - `task_timer_panel.dart`
  - `task_manual_time_entry_dialog.dart`
- Existing timer tests
- Add: `task_timer_apple_visual_test.dart`

- [ ] Replace SnackBar visible fallback with source-mapped Apple transient feedback.
- [ ] Replace Material icon buttons and dialog shell.
- [ ] Preserve one-active-timer and manual entry semantics.
- [ ] Run Task 2.7 complete verifier.
- [ ] Commit:

```bash
git commit -m "feat: migrate task timer to apple visual foundation"
```

## Gate G4 — List/Kanban/Calendar

**Files:**
- Modify:
  - `task_kanban_board.dart`
  - `task_calendar_board.dart`
  - relevant Tasks panel view-mode visuals
- Existing board/calendar tests
- Add:
  - `task_kanban_apple_visual_test.dart`
  - `task_calendar_apple_visual_test.dart`

- [ ] Migrate column/card/calendar chrome, controls and typography.
- [ ] Preserve drag/drop, ordering, occurrence projection and exception behavior.
- [ ] Run Task 2.6 complete verifier.
- [ ] Commit:

```bash
git commit -m "feat: migrate task views to apple visual foundation"
```

---

# Gate H — Remove Legacy Visual Foundation From Production Use

### Task 8: Retire `Original*` visual APIs after all consumers migrate

**Files:**
- Delete only when unused:
  - `lib/app/theme/original_design_tokens.dart`
  - `lib/app/theme/original_theme.dart`
  - `lib/app/widgets/original_glass.dart`
  - `lib/app/widgets/original_controls.dart`
  - `lib/app/widgets/aurora_background.dart`
- Evaluate `original_icon.dart` separately; replace/delete only after all icon consumers use `AppleIcon`.
- Update tests importing `OriginalTheme`.

**Interfaces:**
- `AppleVisualThemeData` is the sole production visual theme source.
- No `OriginalPalette.of(context)` remains in migrated production presentation code.

- [ ] **Step 1: RED legacy-reference verifier**

Extend `tool/verify_visual_foundation_2a_no_visual_fallback.py` to reject production references to:

```text
OriginalTheme
OriginalPalette
OriginalGlass
OriginalFieldSurface
OriginalPrimaryButton
OriginalGhostButton
OriginalTextField
AuroraBackground
```

- [ ] **Step 2: Remove final imports/usages**

Use:

```bash
rg -n 'OriginalTheme|OriginalPalette|OriginalGlass|OriginalFieldSurface|OriginalPrimaryButton|OriginalGhostButton|OriginalTextField|AuroraBackground' lib
```

Expected at Gate H completion: no production matches, except an explicitly documented non-runtime migration fixture if one is intentionally retained.

- [ ] **Step 3: Delete dead legacy files**

Delete only after `rg` and tests prove no runtime dependency.

- [ ] **Step 4: Update test host**

All presentation tests use `AppleVisualTestHost` rather than `MaterialApp(theme: OriginalTheme.light())`.

- [ ] **Step 5: Run Gate H**

```bash
python3 tool/verify_visual_foundation_2a_no_visual_fallback.py
/home/shabin/develop/flutter/bin/flutter test test/app test/features
/home/shabin/develop/flutter/bin/flutter analyze
git diff --check
```

- [ ] **Step 6: Commit Gate H**

```bash
git add lib test tool
git commit -m "refactor: retire legacy dashboard visual foundation"
```

---

# Gate I — Full Fidelity, Performance and Regression Closure

### Task 9: Verify every source-locked boundary before checkpoint

**Files:**
- Create: `tool/verify_visual_foundation_2a_green.py`
- Create: `docs/superpowers/checkpoints/<date>-visual-foundation-2a-checkpoint.md` only after implementation SHA exists.
- Create: `tool/verify_visual_foundation_2a_complete.py` only after implementation SHA exists.
- Modify: `PROJECT_ROADMAP.md` only at checkpoint boundary.

**Green verifier must assert:**

- source hashes;
- generated reference presence;
- iOS/macOS family mapping;
- no unresolved required source token;
- zero unapproved renderer deviations;
- no forbidden visible Material/Fluent/native fallback in migrated presentation code;
- no legacy `Original*` production visual usage;
- light/dark fidelity fixtures exist;
- iOS/macOS fixture coverage exists;
- Task 2.8 complete verifier remains green;
- Task 2.7/2.6 prior complete verifiers remain green;
- `git diff --check`.

- [ ] **Step 1: Focused Visual Foundation suite**

```bash
/home/shabin/develop/flutter/bin/flutter test test/app/apple_visual
```

- [ ] **Step 2: Feature presentation regression**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/features/dashboard \
  test/features/tasks/presentation
```

- [ ] **Step 3: Prior semantic verifiers**

```bash
python3 tool/verify_phase2_task2_5_complete.py
python3 tool/verify_phase2_task2_6_complete.py
python3 tool/verify_phase2_task2_7_complete.py
python3 tool/verify_phase2_task2_8_complete.py
python3 tool/verify_visual_foundation_2a_green.py
```

- [ ] **Step 4: Analyzer**

```bash
/home/shabin/develop/flutter/bin/flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Full suite**

```bash
/home/shabin/develop/flutter/bin/flutter test
```

Record the actual fresh count; do not copy the historical `1245`.

- [ ] **Step 6: Linux debug build**

```bash
/home/shabin/develop/flutter/bin/flutter build linux --debug
```

- [ ] **Step 7: Android verification**

At minimum, once Android runner/config is available:

```bash
/home/shabin/develop/flutter/bin/flutter build apk --debug
```

If Android host files are not present in the repository, this is a discovered implementation prerequisite, not a reason to claim Android fidelity verified.

- [ ] **Step 8: Performance evidence**

Profile the highest-cost glass scenes at fixed sizes.

No automatic visual degradation is allowed to hit a performance target.

If exactness causes unacceptable rendering cost, report the exact scene/frame evidence and stop for an explicit trade-off decision.

- [ ] **Step 9: Diff check**

```bash
git diff --check
```

- [ ] **Step 10: Implementation commit**

Only after all green gates:

```bash
git add <explicit Visual Foundation implementation/test files>
git commit -m "feat: migrate app to exact apple liquid glass visual foundation"
git push
git rev-parse HEAD
```

Record the exact full SHA.

- [ ] **Step 11: Checkpoint**

Checkpoint must record:

- exact implementation SHA;
- exact source hashes;
- exact focused test count;
- exact full-suite count;
- analyze result;
- Linux build result;
- Android build result/status;
- source fidelity/golden evidence;
- accepted deviations: **none**, unless the user explicitly approved named deviations;
- prior Task 2.5–2.8 verifier results.

- [ ] **Step 12: Complete verifier + Roadmap advance**

Only after checkpoint SHA exists:

- create `tool/verify_visual_foundation_2a_complete.py`;
- mark Visual Foundation 2.A `IMPLEMENTED AND FRESHLY VERIFIED`;
- return `CURRENT TASK` to Task 2.9;
- keep frozen Apple visual contract as a permanent project-wide invariant;
- push checkpoint/governance boundary.

---

## Required Test Matrix

Every shared visual primitive/control that is present on both families must cover:

| Dimension | Values |
|---|---|
| Family | iOS 27, macOS 27 |
| Appearance | Light, Dark |
| Direction | RTL primary; LTR sanity where existing localization supports it |
| State | applicable idle/hover/pressed/selected/disabled/focused |
| DPR | fixed per reference fixture |
| Size | exact source size class |
| Background | exact controlled light/dark source-relevant background |

Feature fixtures need not multiply every domain state by every visual dimension; shared primitive tests own the combinatorial visual matrix, while feature fixtures cover representative integration states.

---

## Explicit Non-Acceptance Conditions

Visual Foundation 2.A must remain incomplete if any of these are true:

1. Android uses Material visual controls as a fallback.
2. Windows/Linux uses Fluent/native visual controls as a fallback.
3. any migrated component still uses hand-tuned blur/radius/shadow/color because the source value was not extracted;
4. a required font is unresolved but a substitute is silently used;
5. required Apple-like icons are replaced by Material Icons without a source-locked mapping;
6. a renderer mismatch is accepted without explicit user approval;
7. current feature behavior regresses;
8. Task 2.8 semantic verifier breaks;
9. only light or only dark is fidelity-tested;
10. only desktop or only mobile family is fidelity-tested;
11. app-generated goldens are used as the sole “reference” instead of Apple-source-derived reference fixtures.

---

## Plan Self-Review

### Spec coverage

Covered:

- source manifest enforcement;
- exact iOS/mobile mapping;
- exact macOS/desktop mapping;
- centralized semantic tokens;
- typography;
- materials/Liquid Glass;
- state resolution;
- shared controls;
- app shell;
- existing screen migration;
- light/dark;
- desktop/mobile;
- screenshot/golden fidelity;
- renderer deviation handling;
- performance;
- regression;
- no database changes;
- Task 2.9 blocking and final unblocking.

### Known blockers that must be resolved with source evidence, not guesses

1. Exact Persian-capable Apple typography on Windows/Linux/Android.
2. Exact icon/vector strategy for Apple-equivalent symbols across non-Apple platforms.
3. Any Liquid Glass compositor behavior not represented in the static Sketch source.
4. Android runner/build availability in the current repository; the audit output did not establish an `android/` host tree.

These are not reasons to weaken the requirement. They are explicit Gate A / Gate I blockers.

### Placeholder scan

No unresolved placeholder markers or deferred-implementation markers are allowed in execution. Any source value that is not known is represented as a blocking unresolved source item and cannot be replaced by a guessed value.

### Type consistency

Core public names frozen by this plan:

- `AppleVisualFamily`
- `AppleVisualPlatformResolver`
- `AppleVisualThemeData`
- `AppleColorTokens`
- `AppleTypographyTokens`
- `AppleMetricTokens`
- `AppleMaterialTokens`
- `AppleMotionTokens`
- `AppleControlState`
- `AppleGlassRole`
- `AppleLiquidGlass`
- `AppleRendererDeviation`

Later tasks must use these exact names unless the plan itself is revised and recommitted before implementation proceeds.
