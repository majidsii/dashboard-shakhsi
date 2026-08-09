# Apple Liquid Glass Visual-System Migration — Approved Change Request

Date: 2026-08-09
Status: **APPROVED — DOCUMENTATION LOCK**
Boundary: **Visual Foundation 2.A — Apple Liquid Glass System Migration**

## Change

The current application visual language is to be replaced by a source-locked Apple Liquid Glass visual system based on the supplied iOS 27 and macOS 27 Sketch kits.

This is a global visual-system migration, not a feature-level restyle.

## Explicit user requirements

- exact fidelity, not approximation;
- Android/mobile uses iOS 27 styling exactly;
- Windows/Linux desktop uses macOS 27 styling exactly;
- light and dark appearances are both required;
- no Material fallback;
- no Fluent/native Windows/Linux visual fallback;
- no arbitrary hand-tuned replacement for source-derived values;
- existing feature behavior must survive the migration.

## Why this blocks Task 2.9

Task 2.9 would otherwise introduce new UI using the old visual foundation and immediately create more migration work.

Therefore Visual Foundation 2.A becomes the blocking CURRENT TASK before Task 2.9.

Task 2.8 remains fully completed and is not reopened.

## Canonical documents

Read in this order:

1. `PROJECT_ROADMAP.md`
2. `docs/superpowers/references/2026-08-09-apple-ui-kit-source-manifest.md`
3. `docs/superpowers/specs/2026-08-09-apple-liquid-glass-fidelity-contract.md`
4. `docs/superpowers/specs/2026-08-09-apple-liquid-glass-visual-system-design.md`

The fidelity contract overrides looser visual wording elsewhere.
