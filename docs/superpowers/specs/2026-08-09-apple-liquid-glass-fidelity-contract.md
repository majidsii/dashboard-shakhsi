# Apple Liquid Glass — Frozen Fidelity Contract

Date: 2026-08-09
Status: **APPROVED AND FROZEN**
Boundary: **Visual Foundation 2.A — Apple Liquid Glass System Migration**
Project: `dashboard-shakhsi-v2-integration`

## 1. Non-negotiable target

The application must reproduce the supplied Apple UI references with **source-locked fidelity**.

The accepted target is not:

- Apple-inspired;
- approximately Apple;
- close enough;
- similar to Liquid Glass;
- Material with glass effects;
- Fluent with glass effects;
- a custom design loosely based on Apple.

If the source contains an exact measurable value or state, that source value/state is authoritative.

## 2. Frozen platform mapping

### Mobile

Reference family: **Apple iOS 27 UI Kit**

Applies to:

- Android;
- compact/mobile layouts;
- iOS if/when shipped.

Android must intentionally reproduce the iOS 27 visual system. Material styling is not an accepted fallback.

### Desktop

Reference family: **Apple macOS 27 UI Kit**

Applies to:

- Windows;
- Linux;
- regular/expanded desktop layouts;
- macOS if/when shipped.

Windows and Linux must intentionally reproduce the macOS 27 visual system. Fluent, Windows-native and Linux-native visual styling are not accepted fallbacks.

## 3. Exactness contract

When the source provides a value, do not substitute a hand-tuned or visually similar value.

This applies to:

- width/height and control size classes;
- padding, gap and alignment;
- corner geometry/radii;
- typography role, size, weight and line metrics;
- icon size/baseline/alignment;
- semantic colors;
- light/dark variants;
- fill and opacity;
- separators and strokes;
- shadows and highlights;
- material/glass treatment;
- tint;
- backdrop behavior;
- hover;
- pressed/clicked;
- selected;
- disabled;
- focus;
- editing/value/empty states where present;
- sidebars;
- titlebars/toolbars;
- tab bars;
- menus;
- dialogs;
- alerts;
- popovers;
- sheets;
- lists/forms;
- windows and chrome.

No feature widget may introduce arbitrary visual magic numbers for these concerns.

## 4. Liquid Glass contract

A blurred translucent rectangle is not an implementation of this requirement.

Liquid Glass must be centralized and source-calibrated as a compound rendering treatment covering the corresponding source-defined combination of:

- backdrop;
- translucency;
- tint;
- semantic foreground contrast;
- edge/specular highlight;
- stroke/separator;
- shadow/elevation;
- geometry;
- interactive state changes;
- light/dark adaptation.

No renderer/platform limitation grants permission to silently approximate.

If Windows, Linux, Android or Flutter cannot reproduce a source effect exactly, that mismatch:

1. remains a blocking fidelity defect by default;
2. must be isolated to the rendering layer;
3. must be measured and documented;
4. must identify platform and technical cause;
5. must show reference-vs-render evidence;
6. requires explicit user approval before being accepted as a deviation.

## 5. Central architecture rule

Apple styling belongs to a shared visual-system boundary, not individual feature screens.

Feature widgets express semantic intent and consume centralized primitives/tokens.

The visual foundation owns, at minimum:

- semantic color roles;
- typography roles;
- component dimensions;
- spacing;
- radii;
- materials;
- Liquid Glass rendering;
- light/dark behavior;
- component interaction states;
- motion;
- platform reference mapping;
- desktop pointer/focus treatment;
- mobile navigation/sheet treatment.

## 6. Fidelity verification rule

A component is not complete because it looks right by eye.

Completion requires controlled reference comparison using:

- fixed viewport;
- fixed device pixel ratio;
- fixed appearance;
- fixed component state;
- fixed reference source;
- screenshot/golden capture;
- aligned comparison;
- geometry verification;
- typography verification;
- color/material verification;
- state verification.

Any undocumented mismatch means the component is incomplete.

## 7. Product behavior protection

This boundary is visual-system work.

It must not silently alter domain/business behavior, persistence semantics or prior checkpoint contracts.

Task 2.8 remains completed and immutable unless a verified defect is discovered.

The following are not changed merely for styling:

- Task persistence semantics;
- reminder behavior;
- recurrence behavior;
- timers/time entries;
- task ordering/status semantics;
- template behavior;
- database schema.

## 8. Roadmap lock

Normal functional Task 2.9 is blocked by Visual Foundation 2.A.

Do not begin Task 2.9 implementation until Visual Foundation 2.A has:

1. approved canonical design;
2. detailed implementation plan;
3. source-derived token/component extraction;
4. implementation;
5. fidelity verification;
6. behavioral regression verification;
7. checkpoint;
8. pushed checkpoint commit.

Historical Task numbering must not be rewritten.

## 9. Future-chat invariant

A new assistant/session must not reinterpret this request.

The phrase **Apple Liquid Glass** in this project means:

> Android/mobile reproduces the supplied iOS 27 visual system exactly, and Windows/Linux desktop reproduces the supplied macOS 27 visual system exactly, using the source files identified by the source manifest.

No future session may downgrade this to “Apple-like” without explicit user instruction.

## 10. Final acceptance statement

The target is visual indistinguishability from the corresponding supplied Apple reference at the same layout/component/state.

Anything merely similar does not satisfy this contract.
