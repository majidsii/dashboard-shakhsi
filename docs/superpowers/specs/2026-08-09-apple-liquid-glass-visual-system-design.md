# Visual Foundation 2.A — Apple Liquid Glass System Migration Design

Date: 2026-08-09
Status: **DESIGN APPROVED — IMPLEMENTATION NOT STARTED**
Project: `dashboard-shakhsi-v2-integration`

Canonical source manifest:

`docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md`

Frozen fidelity contract:

`docs/superpowers/specs/2026-08-09-apple-liquid-glass-fidelity-contract.md`

## 1. Objective

Replace the current application visual foundation with a centralized, source-derived Apple Liquid Glass system while preserving existing functional behavior.

The fidelity contract is strict: this is a reproduction target, not an inspiration target.

## 2. Platform reference mapping

### Android / mobile / compact

Use the supplied **Apple iOS 27 UI Kit** as the visual source of truth.

This includes the iOS reference treatment for relevant:

- colors/materials;
- text styles/dynamic type hierarchy;
- system chrome;
- buttons;
- alerts/action sheets;
- lists;
- menus;
- popovers;
- sheets;
- sidebars where applicable;
- segmented controls;
- tab bars;
- text fields;
- toggles;
- toolbars;
- progress/sliders/steppers;
- mobile interaction states.

Material styling is out of scope as a visual fallback.

### Windows / Linux / desktop

Use the supplied **Apple macOS 27 UI Kit** as the visual source of truth.

This includes the macOS reference treatment for relevant:

- colors/materials;
- alerts/dialogs;
- buttons;
- menus;
- popovers;
- sidebars;
- windows;
- titlebars/toolbars;
- search/text fields;
- segmented controls;
- toggles;
- scrollbars;
- progress/sliders/steppers;
- notifications/tooltips;
- pointer/focus/hover/clicked states.

Fluent/native Windows/Linux styling is out of scope as a visual fallback.

## 3. Source precedence

For all visual decisions:

1. exact supplied Sketch component/state;
2. source-derived shared styles/swatches/text styles/materials;
3. this frozen contract/design;
4. existing application structure;
5. framework defaults.

Lower-priority sources cannot override higher-priority visual evidence.

If a required value has not yet been extracted from the supplied Sketch file, it remains **unresolved** and must not be guessed.

## 4. Architectural boundary

The app needs one shared Apple visual foundation.

Conceptual responsibilities:

- Apple semantic color tokens;
- Apple typography tokens;
- Apple platform metrics;
- Apple dimensions/spacing/radius tokens;
- Apple material/Liquid Glass recipes;
- Apple state resolver;
- Apple motion/transition tokens;
- shared desktop/mobile Apple controls;
- screenshot/golden fidelity harness.

Exact Dart class/file names are not frozen by this design. They must be chosen in the implementation plan after auditing the existing theme/widget architecture.

The architectural invariant is frozen:

> feature code requests semantic UI; the visual foundation owns Apple rendering details.

## 5. No local styling drift

Feature code must not independently hard-code:

- blur sigma;
- glass opacity;
- material tint;
- component radius;
- component height;
- Apple semantic label/fill colors;
- control-state colors;
- Apple shadows/highlights;
- platform-specific Apple spacing.

Any reusable source-defined value belongs in the visual foundation.

## 6. Material and Liquid Glass system

Liquid Glass is a reusable material system, not a card decoration.

The implementation must derive the applicable recipes from the source and represent differences across:

- iOS vs macOS;
- light vs dark;
- component family;
- size class;
- ordinary surface vs over-glass state;
- enabled/pressed/selected/disabled/focused state where supplied.

Rendering fidelity must be verified against fixed reference captures.

## 7. Typography

Typography is platform-specific.

Mobile uses source-derived iOS typography roles/metrics.

Desktop uses source-derived macOS typography roles/metrics.

Do not implement mobile typography as a scaled desktop typography table or vice versa.

Where bundled fonts/licensing affect runtime packaging, that is an implementation constraint to solve without silently changing the target metrics.

## 8. Color semantics

Do not reduce Apple colors to a generic accent/background/text palette.

The source contains semantic light/dark and component/state distinctions.

The token extraction phase must preserve semantic roles rather than flattening them into arbitrary opacity levels.

## 9. Geometry and layout

The source controls:

- component dimensions;
- corner geometry;
- internal padding;
- control-to-label spacing;
- group spacing;
- toolbar/sidebar/tab-bar geometry;
- dialog/sheet/popover geometry;
- state-dependent size/appearance where present.

Responsive adaptation is allowed only where the source or app layout requirements actually require it; it is not permission to alter component geometry casually.

## 10. Interaction states

Desktop fidelity must cover applicable:

- idle;
- hover;
- clicked/pressed;
- selected;
- disabled;
- focus;
- pointer/cursor behavior.

Mobile fidelity must cover applicable:

- idle;
- pressed;
- selected;
- disabled;
- focus/editing;
- sheet/menu/modal states.

A control with only its idle appearance migrated is not complete.

## 11. Light and dark

Light and dark are separate source-derived appearances.

Dark mode must not be generated by simple color inversion or generic opacity changes.

Both appearances require independent fidelity evidence.

## 12. Accessibility/adaptation

Reduced motion/transparency/accessibility behavior may require platform-specific implementation.

Such behavior must preserve the Apple visual hierarchy as closely as the platform allows and cannot silently redefine the default visual target.

Accessibility fallbacks must be separately tested from the canonical default fidelity captures.

## 13. Migration order

This design freezes the following implementation sequence, while leaving code-level task breakdown for the implementation plan:

### Gate A — Source extraction

- exact component inventory;
- exact semantic colors;
- exact text styles;
- exact geometry;
- exact materials;
- exact state variants;
- exact platform mapping.

### Gate B — Foundation primitives

- tokens;
- Liquid Glass/material primitive;
- state resolver;
- typography;
- platform metrics;
- shared fidelity harness.

### Gate C — App shell

Desktop macOS-style shell and mobile iOS-style shell.

### Gate D — Shared controls

Migrate reusable controls before feature screens.

### Gate E — Existing screens

Move existing feature UI onto the shared foundation without changing business behavior.

### Gate F — Fidelity/regression

- light/dark;
- desktop/mobile;
- required control states;
- golden/reference comparison;
- full existing behavioral suite;
- analyze;
- Linux build;
- applicable Android build/tests;
- diff check;
- checkpoint verifier.

## 14. Fidelity gate

For each migrated visual unit, the implementation plan must identify:

- Apple source page/component/state;
- extracted source values;
- target viewport/DPR;
- expected light/dark state;
- expected interaction state;
- screenshot/golden evidence;
- allowed deviation: **none by default**.

An unavoidable renderer mismatch is not accepted by engineering judgment alone. It requires explicit user approval for that specific deviation.

## 15. Performance

Backdrop/glass effects must be profiled.

Performance optimization may change implementation technique but may not silently change the visual contract.

If exact rendering and performance conflict, expose the conflict with evidence rather than weakening fidelity automatically.

## 16. Functional compatibility

Visual Foundation 2.A does not change the existing domain/data contracts.

At minimum, preserve:

- Tasks/List/Kanban/Calendar behavior;
- Task Details behavior;
- reminders;
- recurrence;
- timer/time entries;
- Quick-Entry Templates;
- persistence providers;
- schema-8 restart/migration behavior.

No database schema change is currently required by this design.

## 17. Task 2.8 and Task 2.9 boundary

Task 2.8 remains implemented, checkpointed and semantically verified.

Task 2.9 remains functionally pending and is blocked.

Do not implement Task 2.9 until this visual foundation is implemented and checkpointed.

After Visual Foundation 2.A completes, Task 2.9 must be designed/implemented directly on the new Apple visual foundation.

## 18. Documentation/handoff invariant

Every new development chat/session must read:

1. `PROJECT_ROADMAP.md`;
2. source manifest;
3. frozen fidelity contract;
4. this design;
5. only then relevant code/current implementation plan.

Do not ask whether Android should use Material or whether Windows/Linux should use native styling. That decision is already frozen.

Do not reinterpret “exact” as “similar”.

## 19. Non-goals

This design does not itself implement:

- Task 2.9;
- trash/audit/undo;
- new business features;
- billing/Pomodoro;
- database changes;
- unrelated refactors.

## 20. Exit criteria for Visual Foundation 2.A

The boundary is complete only when:

- source extraction is reproducible;
- required shared visual primitives are implemented;
- Android/mobile uses the iOS 27 source mapping;
- Windows/Linux desktop uses the macOS 27 source mapping;
- required existing screens are migrated;
- required states/light/dark variants are fidelity-tested;
- no undocumented visual deviations remain;
- existing functional regression suite passes;
- analyzer/build/diff gates pass;
- exact implementation commit is pushed;
- a Visual Foundation 2.A checkpoint records fresh evidence;
- a semantic verifier passes;
- checkpoint commit is pushed;
- `PROJECT_ROADMAP.md` advances back to functional Task 2.9.
