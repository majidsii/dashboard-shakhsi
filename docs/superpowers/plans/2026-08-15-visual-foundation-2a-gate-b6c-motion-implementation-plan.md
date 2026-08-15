# Visual Foundation 2.A Gate B.6C Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve `AppleMotionTokens` from the approved official SwiftUI runtime reference deviation using exact documented spring defaults, explicit provenance/claim metadata, and an explicit Reduce Motion policy boundary.

**Architecture:** A committed local reference manifest records the two approved SwiftUI spring presets and their provenance. A deterministic generator converts that manifest into generated Dart. `AppleSourceTokenMapper.motion(...)` maps the generated records into immutable foundation types. Both Apple visual families use the same approved numeric reference values. The final task verifies the aggregate theme-resolution boundary and records Gate B status without advancing Gate C unless every Gate B group is genuinely resolved.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Python 3, Flutter test, deterministic generated Dart, approved SwiftUI runtime reference deviation.

## Global Constraints

- Approved decision: `docs/superpowers/decisions/2026-08-15-b6c-swiftui-motion-runtime-reference-deviation.md`.
- Approved design: `docs/superpowers/specs/2026-08-15-visual-foundation-2a-gate-b6c-motion-design.md`.
- Motion source class: `OFFICIAL_SWIFTUI_RUNTIME_REFERENCE`.
- `defaultSpring` exact values: `responseSeconds = 0.55`, `dampingFraction = 1.0`, `blendDurationSeconds = 0.0`.
- `interactiveSpring` exact values: `responseSeconds = 0.15`, `dampingFraction = 0.86`, `blendDurationSeconds = 0.25`.
- `officialSwiftUIRuntimeReference = true`.
- `exactInternalLiquidGlassMotion = false`.
- Reduce Motion policy must be explicit.
- No additional duration, easing, stiffness, mass, velocity, bounce, bezier, interpolation, or spring constants may be invented in B.6C.
- Android/iOS remain in the iOS 27 visual family; Windows/Linux/macOS remain in the macOS 27 visual family.
- Both visual families use the same approved SwiftUI runtime motion reference values.
- B.1-B.6B must remain GREEN.
- Do not implement animation widgets, Liquid Glass rendering, host accessibility listeners, dashboard migration, Gate C, OriginalTheme retirement, or Task 2.9 in B.6C.
- Never run `flutter upgrade`.
- Never modify, stage, or delete unrelated IPSW files.
- Generated Dart remains byte-for-byte generator-owned; do not post-format generated output.
- Gate B production work remains uncommitted until the final approved Gate B checkpoint. Never use `git add .`.

---

## File Structure

### Create

- `docs/superpowers/references/apple_swiftui_motion_runtime_reference.json`
  - Local immutable manifest for the approved official SwiftUI runtime values and provenance.

- `tool/generate_apple_source_motion.py`
  - Validates the manifest contract, locks exact approved values, generates Dart deterministically, and supports `--check`.

- `lib/app/apple_visual/generated/apple_source_motion.g.dart`
  - Generated motion-source records only.

- `test/app/apple_visual/apple_motion_mapping_test.dart`
  - RED/GREEN contract for values, provenance, cross-family equality, and Reduce Motion policy.

### Modify

- `lib/app/apple_visual/foundation/apple_visual_motion.dart`
  - Replace the unresolved-only shell with the approved motion domain model while preserving `AppleMotionTokens.empty`.

- `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
  - Add generated-source-backed `motion({required AppleVisualFamily family})`.

- `test/app/apple_visual/apple_visual_tokens_contract_test.dart`
  - Verify aggregate theme resolution once every required token group is resolved.

- `docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md`
  - Record B.6C GREEN and final Gate B verification status only after fresh evidence.

### Read-only Inputs

- B.6C approved decision/spec.
- Existing B.1-B.6B foundation code, generators, generated files, and tests.

---

### Task 1: Lock the B.6C RED Contract

**Files:**
- Create: `test/app/apple_visual/apple_motion_mapping_test.dart`
- Read: `lib/app/apple_visual/foundation/apple_visual_motion.dart`
- Read: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`

**Interfaces:**
- Consumes:
  - `AppleVisualFamily.ios27`
  - `AppleVisualFamily.macos27`
- Produces the required public contract:
  - `enum AppleMotionPreset { defaultSpring, interactiveSpring }`
  - `enum AppleMotionAccessibilityPolicy { standard, reduceMotion }`
  - `class AppleMotionProvenance`
  - `class AppleSpringMotion`
  - `class AppleMotionTokens`
  - `AppleMotionTokens AppleSourceTokenMapper.motion({required AppleVisualFamily family})`

- [ ] **Step 1: Write the failing exact-value test**

Create assertions equivalent to:

```dart
final ios = AppleSourceTokenMapper.motion(
  family: AppleVisualFamily.ios27,
);

expect(ios.isResolved, isTrue);

expect(ios.defaultSpring.preset, AppleMotionPreset.defaultSpring);
expect(ios.defaultSpring.responseSeconds, 0.55);
expect(ios.defaultSpring.dampingFraction, 1.0);
expect(ios.defaultSpring.blendDurationSeconds, 0.0);

expect(
  ios.interactiveSpring.preset,
  AppleMotionPreset.interactiveSpring,
);
expect(ios.interactiveSpring.responseSeconds, 0.15);
expect(ios.interactiveSpring.dampingFraction, 0.86);
expect(ios.interactiveSpring.blendDurationSeconds, 0.25);
```

- [ ] **Step 2: Lock machine-visible provenance and claim boundary**

```dart
for (final motion in <AppleSpringMotion>[
  ios.defaultSpring,
  ios.interactiveSpring,
]) {
  expect(motion.provenance.officialSwiftUIRuntimeReference, isTrue);
  expect(motion.provenance.exactInternalLiquidGlassMotion, isFalse);
  expect(motion.provenance.apiReference, isNotEmpty);
}
```

- [ ] **Step 3: Lock cross-family equality**

```dart
final macos = AppleSourceTokenMapper.motion(
  family: AppleVisualFamily.macos27,
);

expect(macos.defaultSpring.responseSeconds, ios.defaultSpring.responseSeconds);
expect(
  macos.defaultSpring.dampingFraction,
  ios.defaultSpring.dampingFraction,
);
expect(
  macos.defaultSpring.blendDurationSeconds,
  ios.defaultSpring.blendDurationSeconds,
);

expect(
  macos.interactiveSpring.responseSeconds,
  ios.interactiveSpring.responseSeconds,
);
expect(
  macos.interactiveSpring.dampingFraction,
  ios.interactiveSpring.dampingFraction,
);
expect(
  macos.interactiveSpring.blendDurationSeconds,
  ios.interactiveSpring.blendDurationSeconds,
);
```

- [ ] **Step 4: Lock Reduce Motion policy**

```dart
expect(
  ios.accessibilityPolicies,
  containsAll(<AppleMotionAccessibilityPolicy>[
    AppleMotionAccessibilityPolicy.standard,
    AppleMotionAccessibilityPolicy.reduceMotion,
  ]),
);
```

The test must not invent a replacement Reduce Motion duration.

- [ ] **Step 5: Run RED**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_motion_mapping_test.dart
```

Expected: compile/test failure because the approved B.6C API is absent.

Reject RED if failure is caused by malformed Dart, bad imports, or unrelated Gate B regressions.

- [ ] **Step 6: Re-run B.1-B.6B focused regression**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_visual_platform_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_source_reference_mapping_test.dart \
  test/app/apple_visual/apple_semantic_color_mapping_test.dart \
  test/app/apple_visual/apple_typography_mapping_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart
```

Expected: all pass.

**Task boundary:** RED only. No B.6C production implementation and no production commit.

---

### Task 2: Create the Locked SwiftUI Motion Reference Manifest and Generator

**Files:**
- Create: `docs/superpowers/references/apple_swiftui_motion_runtime_reference.json`
- Create: `tool/generate_apple_source_motion.py`
- Create: `lib/app/apple_visual/generated/apple_source_motion.g.dart`
- Test: `test/app/apple_visual/apple_motion_mapping_test.dart`

**Interfaces:**
- Manifest schema:
  - `referenceClass`
  - `verifiedAt`
  - `presets`
  - `accessibilityPolicies`
- Generated interfaces:
  - `AppleGeneratedMotionProvenance`
  - `AppleGeneratedSpringMotion`
  - `AppleSourceMotionReference.defaultSpring`
  - `AppleSourceMotionReference.interactiveSpring`
  - `AppleSourceMotionReference.accessibilityPolicies`

- [ ] **Step 1: Create the approved local manifest**

The manifest must contain exactly:

```json
{
  "referenceClass": "officialSwiftUIRuntimeReference",
  "verifiedAt": "2026-08-15",
  "presets": [
    {
      "id": "defaultSpring",
      "apiReference": "Animation.default",
      "responseSeconds": 0.55,
      "dampingFraction": 1.0,
      "blendDurationSeconds": 0.0,
      "officialSwiftUIRuntimeReference": true,
      "exactInternalLiquidGlassMotion": false
    },
    {
      "id": "interactiveSpring",
      "apiReference": "Animation.interactiveSpring(response:dampingFraction:blendDuration:)",
      "responseSeconds": 0.15,
      "dampingFraction": 0.86,
      "blendDurationSeconds": 0.25,
      "officialSwiftUIRuntimeReference": true,
      "exactInternalLiquidGlassMotion": false
    }
  ],
  "accessibilityPolicies": [
    "standard",
    "reduceMotion"
  ]
}
```

Do not add additional motion numeric values.

- [ ] **Step 2: Implement strict manifest validation**

`tool/generate_apple_source_motion.py` must reject any manifest where:

```python
EXPECTED = {
    "defaultSpring": (0.55, 1.0, 0.0),
    "interactiveSpring": (0.15, 0.86, 0.25),
}
```

does not match exactly.

It must also require:

```python
referenceClass == "officialSwiftUIRuntimeReference"
officialSwiftUIRuntimeReference is True
exactInternalLiquidGlassMotion is False
accessibilityPolicies == ["standard", "reduceMotion"]
```

- [ ] **Step 3: Generate deterministic Dart**

Generated Dart must expose records equivalent to:

```dart
class AppleGeneratedMotionProvenance {
  const AppleGeneratedMotionProvenance({
    required this.apiReference,
    required this.officialSwiftUIRuntimeReference,
    required this.exactInternalLiquidGlassMotion,
  });

  final String apiReference;
  final bool officialSwiftUIRuntimeReference;
  final bool exactInternalLiquidGlassMotion;
}
```

```dart
class AppleGeneratedSpringMotion {
  const AppleGeneratedSpringMotion({
    required this.id,
    required this.responseSeconds,
    required this.dampingFraction,
    required this.blendDurationSeconds,
    required this.provenance,
  });

  final String id;
  final double responseSeconds;
  final double dampingFraction;
  final double blendDurationSeconds;
  final AppleGeneratedMotionProvenance provenance;
}
```

- [ ] **Step 4: Implement `--check` and deterministic regeneration**

Commands:

```bash
python3 tool/generate_apple_source_motion.py \
  --input docs/superpowers/references/apple_swiftui_motion_runtime_reference.json \
  --output lib/app/apple_visual/generated/apple_source_motion.g.dart

python3 tool/generate_apple_source_motion.py \
  --input docs/superpowers/references/apple_swiftui_motion_runtime_reference.json \
  --output lib/app/apple_visual/generated/apple_source_motion.g.dart \
  --check
```

Regenerate twice and assert identical SHA-256.

Do not run `dart format` on `apple_source_motion.g.dart`.

- [ ] **Step 5: Prove no extra numeric motion constants exist in the manifest**

A verification script must collect all numeric motion payload values and assert exactly:

```text
0.55
1.0
0.0
0.15
0.86
0.25
```

excluding non-motion metadata such as the date string.

**Task boundary:** local source reference + generator exist. RED remains RED because runtime foundation mapping is still absent.

---

### Task 3: Implement the Motion Domain Model and Mapper

**Files:**
- Modify: `lib/app/apple_visual/foundation/apple_visual_motion.dart`
- Modify: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
- Consume: `lib/app/apple_visual/generated/apple_source_motion.g.dart`
- Test: `test/app/apple_visual/apple_motion_mapping_test.dart`

**Interfaces:**
- Produces:

```dart
enum AppleMotionPreset {
  defaultSpring,
  interactiveSpring,
}

enum AppleMotionAccessibilityPolicy {
  standard,
  reduceMotion,
}
```

```dart
class AppleMotionProvenance {
  const AppleMotionProvenance({
    required this.apiReference,
    required this.officialSwiftUIRuntimeReference,
    required this.exactInternalLiquidGlassMotion,
  });

  final String apiReference;
  final bool officialSwiftUIRuntimeReference;
  final bool exactInternalLiquidGlassMotion;
}
```

```dart
class AppleSpringMotion {
  const AppleSpringMotion({
    required this.preset,
    required this.responseSeconds,
    required this.dampingFraction,
    required this.blendDurationSeconds,
    required this.provenance,
  });

  final AppleMotionPreset preset;
  final double responseSeconds;
  final double dampingFraction;
  final double blendDurationSeconds;
  final AppleMotionProvenance provenance;
}
```

```dart
class AppleMotionTokens {
  const AppleMotionTokens._({
    required this.isResolved,
    AppleSpringMotion? defaultSpring,
    AppleSpringMotion? interactiveSpring,
    List<AppleMotionAccessibilityPolicy>? accessibilityPolicies,
  });

  static const empty = AppleMotionTokens._(isResolved: false);

  AppleMotionTokens.resolved({
    required AppleSpringMotion defaultSpring,
    required AppleSpringMotion interactiveSpring,
    required List<AppleMotionAccessibilityPolicy> accessibilityPolicies,
  });

  final bool isResolved;

  AppleSpringMotion get defaultSpring;
  AppleSpringMotion get interactiveSpring;

  List<AppleMotionAccessibilityPolicy> get accessibilityPolicies;
}
```

Unresolved getters must throw `StateError` rather than returning guessed defaults.

- [ ] **Step 1: Implement immutable foundation domain types**

All resolved lists must be unmodifiable.

`AppleMotionTokens.empty` must preserve the unresolved B.2 contract.

- [ ] **Step 2: Add generated motion import to mapper**

Add:

```dart
import '../generated/apple_source_motion.g.dart';
import 'apple_visual_motion.dart';
```

without removing any existing B.1-B.6B mappings.

- [ ] **Step 3: Implement exhaustive preset conversion**

```dart
static AppleMotionPreset _motionPreset(String value) {
  return switch (value) {
    'defaultSpring' => AppleMotionPreset.defaultSpring,
    'interactiveSpring' => AppleMotionPreset.interactiveSpring,
    _ => throw StateError(
      'Unsupported generated Apple motion preset: $value',
    ),
  };
}
```

Unknown generated presets must not silently fall back.

- [ ] **Step 4: Implement `AppleSourceTokenMapper.motion(...)`**

The `family` parameter must be accepted and exhaustively switched, but both families must intentionally select the same approved `AppleSourceMotionReference` records.

The mapper must contain no numeric motion literals.

- [ ] **Step 5: Run the B.6C test and verify GREEN**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_motion_mapping_test.dart
```

Expected: all B.6C tests pass.

- [ ] **Step 6: Add mapper no-literal/no-extra-motion guard**

Reject direct numeric motion assignments in `apple_source_token_mapper.dart`, including:

```text
responseSeconds:
dampingFraction:
blendDurationSeconds:
Duration(
Cubic(
stiffness:
mass:
velocity:
bounce:
```

unless values come from generated records rather than numeric literals.

**Task boundary:** `AppleMotionTokens` is functionally resolved. Do not yet claim Gate B complete.

---

### Task 4A: Repair the Incomplete B.5 Typography Token Group Boundary

**Why this task exists:** During Task 4 preflight, repository evidence showed that B.5 created exact source-backed `typographyRole(...)` mapping but never created a resolved `AppleTypographyTokens` group. Because `AppleVisualThemeData.isResolved` requires `typography.isResolved`, a fully resolved theme is currently impossible even though the individual typography roles are source-backed. This is a B.5 completion defect discovered by B.6C verification, not a new visual design decision.

**Files:**
- Modify: `lib/app/apple_visual/foundation/apple_visual_typography.dart`
- Modify: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
- Modify: `test/app/apple_visual/apple_typography_mapping_test.dart`
- Verify: `test/app/apple_visual/apple_visual_tokens_contract_test.dart`

**Interfaces:**
- Existing source role API remains:
  - `AppleSourceTokenMapper.typographyRole({required AppleVisualFamily family, required AppleTypographyRole role})`
- Add the missing group API:
  - `AppleTypographyTokens AppleSourceTokenMapper.typography({required AppleVisualFamily family})`
- `AppleTypographyTokens.resolved(...)` must contain exactly:
  - `body`
  - `headline`
  - `title1`

- [ ] **Step 1: Write a focused RED proving the group boundary is missing**

Add to `apple_typography_mapping_test.dart`:

```dart
for (final family in AppleVisualFamily.values) {
  test('$family typography token group resolves all approved roles', () {
    final typography = AppleSourceTokenMapper.typography(
      family: family,
    );

    expect(typography.isResolved, isTrue);
    expect(
      typography.body.sourceId,
      AppleSourceTokenMapper.typographyRole(
        family: family,
        role: AppleTypographyRole.body,
      ).sourceId,
    );
    expect(
      typography.headline.sourceId,
      AppleSourceTokenMapper.typographyRole(
        family: family,
        role: AppleTypographyRole.headline,
      ).sourceId,
    );
    expect(
      typography.title1.sourceId,
      AppleSourceTokenMapper.typographyRole(
        family: family,
        role: AppleTypographyRole.title1,
      ).sourceId,
    );
  });
}
```

Run only the typography test and verify RED fails because `AppleSourceTokenMapper.typography(...)`, resolved token getters, and/or `AppleTypographyTokens.resolved(...)` are missing.

- [ ] **Step 2: Implement the minimal resolved typography group**

`AppleTypographyTokens` must preserve `empty` and add immutable resolved storage:

```dart
class AppleTypographyTokens {
  const AppleTypographyTokens._({
    required this.isResolved,
    AppleSourceTypographyToken? body,
    AppleSourceTypographyToken? headline,
    AppleSourceTypographyToken? title1,
  }) : _body = body,
       _headline = headline,
       _title1 = title1;

  const AppleTypographyTokens.resolved({
    required AppleSourceTypographyToken body,
    required AppleSourceTypographyToken headline,
    required AppleSourceTypographyToken title1,
  }) : this._(
         isResolved: true,
         body: body,
         headline: headline,
         title1: title1,
       );

  static const empty = AppleTypographyTokens._(isResolved: false);

  final bool isResolved;
  final AppleSourceTypographyToken? _body;
  final AppleSourceTypographyToken? _headline;
  final AppleSourceTypographyToken? _title1;
}
```

Each getter must throw `StateError('Apple typography tokens are unresolved.')` when accessed from `empty`.

- [ ] **Step 3: Add the missing group mapper without changing role semantics**

Implement:

```dart
static AppleTypographyTokens typography({
  required AppleVisualFamily family,
}) {
  return AppleTypographyTokens.resolved(
    body: typographyRole(
      family: family,
      role: AppleTypographyRole.body,
    ),
    headline: typographyRole(
      family: family,
      role: AppleTypographyRole.headline,
    ),
    title1: typographyRole(
      family: family,
      role: AppleTypographyRole.title1,
    ),
  );
}
```

No font size, line height, weight, PostScript name, or font-family values may be duplicated or manually re-entered in this group mapper.

- [ ] **Step 4: Verify GREEN and B.5 regression**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_typography_mapping_test.dart
```

Expected: all typography source-role tests plus the new group-resolution tests pass.

- [ ] **Step 5: Verify unresolved behavior remains intact**

Add/assert:

```dart
expect(AppleTypographyTokens.empty.isResolved, isFalse);
expect(() => AppleTypographyTokens.empty.body, throwsStateError);
expect(() => AppleTypographyTokens.empty.headline, throwsStateError);
expect(() => AppleTypographyTokens.empty.title1, throwsStateError);
```

- [ ] **Step 6: Re-run B.1-B.6C focused regression**

All existing focused tests must pass before returning to aggregate theme verification.

**Task boundary:** this repairs the incomplete B.5 token-group boundary only. It does not change the approved typography source values, Vazirmatn deviation, motion design, or Gate C scope. No production commit yet.

---
### Task 4: Verify Aggregate Theme Resolution

**Files:**
- Modify: `test/app/apple_visual/apple_visual_tokens_contract_test.dart`
- Read: all existing foundation token groups and mapper methods.

**Interfaces:**
- Consumes:
  - resolved source-backed colors
  - resolved source-backed typography
  - resolved variant-aware metrics
  - resolved source-backed materials
  - resolved approved-reference motion
- Produces verified `AppleVisualThemeData.isResolved`.

- [ ] **Step 1: Keep the unresolved-theme regression**

Retain/assert:

```dart
expect(
  const AppleVisualThemeData(
    colors: AppleColorTokens.empty,
    typography: AppleTypographyTokens.empty,
    metrics: AppleMetricTokens.empty,
    materials: AppleMaterialTokens.empty,
    motion: AppleMotionTokens.empty,
  ).isResolved,
  isFalse,
);
```

- [ ] **Step 2: Add fully-resolved theme tests for both visual families**

For each `(family, brightness)` pair:

```dart
final theme = AppleVisualThemeData(
  family: family,
  brightness: brightness,
  colors: AppleSourceTokenMapper.colors(
    family: family,
    brightness: brightness,
  ),
  typography: AppleSourceTokenMapper.typography(family: family),
  metrics: AppleSourceTokenMapper.metrics(family: family),
  materials: AppleSourceTokenMapper.materials(family: family),
  motion: AppleSourceTokenMapper.motion(family: family),
);

expect(theme.isResolved, isTrue);
```

If the existing mapper method names differ, use the already-established B.4-B.6B public names from the codebase; do not create duplicate APIs.

- [ ] **Step 3: Prove motion still gates theme resolution**

Build the same resolved theme except with:

```dart
motion: AppleMotionTokens.empty,
```

Expected:

```dart
expect(theme.isResolved, isFalse);
```

- [ ] **Step 4: Run focused B.1-B.6C tests**

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_visual_platform_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_source_reference_mapping_test.dart \
  test/app/apple_visual/apple_semantic_color_mapping_test.dart \
  test/app/apple_visual/apple_typography_mapping_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart \
  test/app/apple_visual/apple_motion_mapping_test.dart
```

Expected: all pass.

**Task boundary:** theme-resolution behavior is verified. Gate B still requires final verification before checkpoint.

---

### Task 5: Full Gate B Verification

**Files:**
- Verify all Gate A/Gate B source generators, foundation tests, and guards.
- Modify no production files unless a verified defect is discovered.

**Interfaces:**
- Produces evidence for the Gate B checkpoint decision.

- [ ] **Step 1: Verify motion generator freshness/determinism**

Run `generate_apple_source_motion.py --check`, regenerate, compare SHA, and run `--check` again.

- [ ] **Step 2: Verify every pre-existing generated reference remains fresh**

Run `--check` for:

- source reference
- colors
- typography
- materials
- metrics
- motion

Expected: all PASS.

- [ ] **Step 3: Verify Gate A extraction integrity**

Run:

```bash
python3 tool/verify_visual_foundation_2a_sources.py --self-test
python3 tool/verify_visual_foundation_2a_sources.py
```

Expected: both PASS.

- [ ] **Step 4: Run all focused B.1-B.6C Flutter tests**

Expected: all PASS.

- [ ] **Step 5: Run full Flutter test suite**

```bash
/home/shabin/develop/flutter/bin/flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Run static analysis**

```bash
/home/shabin/develop/flutter/bin/flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Build Linux debug application**

```bash
/home/shabin/develop/flutter/bin/flutter build linux --debug
```

Expected: build succeeds.

- [ ] **Step 8: Run `git diff --check`**

Expected: no output, exit 0.

- [ ] **Step 9: Verify no motion-claim drift**

Repository guards must confirm:

```text
OFFICIAL_SWIFTUI_RUNTIME_REFERENCE=YES
EXACT_INTERNAL_LIQUID_GLASS_MOTION=NO
GUESSED_MOTION_VALUES=NONE
REDUCE_MOTION_POLICY=REQUIRED
```

No source or test may claim exact internal Liquid Glass motion.

- [ ] **Step 10: Verify no forbidden fallback styling/motion was introduced**

B.6C must not add:

- Material visual fallback
- Fluent fallback
- Cupertino icon fallback
- arbitrary animation durations/easing
- renderer-specific guessed motion values

**Task boundary:** only fresh evidence from all steps may authorize Gate B completion.

---

### Task 6: Record and Checkpoint Gate B

**Files:**
- Modify: `docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md`
- Modify: `PROJECT_ROADMAP.md`
- Create: `docs/superpowers/checkpoints/2026-08-15-visual-foundation-2a-gate-b-complete-checkpoint.md`

**Interfaces:**
- Consumes complete fresh verification from Task 5.
- Produces the first legitimate Gate B checkpoint.

- [ ] **Step 1: Record B.6C GREEN**

Record:

```text
B.6C motion: GREEN
MOTION_SOURCE=OFFICIAL_SWIFTUI_RUNTIME_REFERENCE
DEFAULT_SPRING=0.55/1.0/0.0
INTERACTIVE_SPRING=0.15/0.86/0.25
EXACT_INTERNAL_LIQUID_GLASS_MOTION=NO
REDUCE_MOTION_POLICY=REQUIRED
GUESSED_MOTION_VALUES=NONE
```

- [ ] **Step 2: Mark Gate B complete only if Task 5 is fully PASS**

The active plan and Roadmap may move from:

```text
GATE B ACTIVE
```

to:

```text
GATE B COMPLETE — NEXT: GATE C
```

only after every Task 5 verification succeeds.

Task 2.9 remains blocked because Visual Foundation 2.A itself is not complete.

- [ ] **Step 3: Create a Gate B checkpoint**

Checkpoint must record:

- B.1-B.6C implementation scope
- exact source hashes for Apple Sketch references
- B.5 typography deviation
- B.6B variant-aware metric architecture
- B.6C official SwiftUI runtime motion deviation
- exact verification commands and outcomes
- generated motion Dart SHA-256
- full test count
- analyze/build result
- `git diff --check`
- next action: Gate C Liquid Glass primitives

- [ ] **Step 4: Stage only Gate B files explicitly**

Never use `git add .`.

Explicitly exclude:

```text
iPhone10,3,iPhone10,6_16.7.16_20H392_Restore.ipsw
iPhone10,3,iPhone10,6_16.7.16_20H392_Restore.ipsw.lock
```

- [ ] **Step 5: Commit Gate B checkpoint**

Commit production + tests + generators + reference manifest + active plan/Roadmap/checkpoint with a Gate B scoped subject.

Do not include unrelated files.

- [ ] **Step 6: Verify the checkpoint commit**

Freshly verify:

```bash
git status -sb
git show --stat --oneline HEAD
```

Then rerun the critical Gate B verifier after commit.

## Expected Gate B Completion Marker

```text
VISUAL_FOUNDATION_2A_GATE_B=PASS
B_1_PLATFORM_FAMILY=PASS
B_2_TOKEN_THEME_BOUNDARY=PASS
B_3_SOURCE_REFERENCE=PASS
B_4_COLORS=PASS
B_5_TYPOGRAPHY=PASS
B_6A_MATERIALS=PASS
B_6B_VARIANT_AWARE_METRICS=PASS
B_6C_MOTION=PASS
MOTION_SOURCE=OFFICIAL_SWIFTUI_RUNTIME_REFERENCE
OFFICIAL_SWIFTUI_RUNTIME_REFERENCE=YES
EXACT_INTERNAL_LIQUID_GLASS_MOTION=NO
REDUCE_MOTION_POLICY=REQUIRED
GUESSED_MOTION_VALUES=NONE
THEME_RESOLVED=YES
FULL_TEST_SUITE=PASS
FLUTTER_ANALYZE=PASS
LINUX_DEBUG_BUILD=PASS
GIT_DIFF_CHECK=PASS
GATE_B_COMPLETE=YES
NEXT=Gate C — Liquid Glass primitives
```

<!-- B6C_EXECUTION_COMPLETE_2026_08_15 -->
## Execution result — 2026-08-15

Status: **COMPLETE**

- Task 1 RED: passed for missing approved motion API.
- Task 2: locked SwiftUI motion reference manifest + deterministic generator.
- Task 3 GREEN: motion domain model + generated-source-backed mapper.
- Task 4A: repaired the discovered B.5 aggregate typography token-group gap via RED/GREEN.
- Task 4: aggregate `AppleVisualThemeData` resolution passed for iOS 27/macOS 27
  in light/dark, and unresolved motion correctly gates theme resolution.
- Task 5: full Gate B verification passed.

Motion contract remains:
- default spring: `0.55 / 1.0 / 0.0`
- interactive spring: `0.15 / 0.86 / 0.25`
- source class: official SwiftUI runtime reference
- exact internal Liquid Glass motion: **false**
- Reduce Motion policy: **required**
- guessed motion values: **none**
