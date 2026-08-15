# Decision — B.6C SwiftUI Motion Runtime Reference Deviation

**Date:** 2026-08-15  
**Status:** APPROVED  
**Scope:** Visual Foundation 2.A — Gate B.6C Motion only

## Context

The frozen Apple iOS 27 and macOS 27 Sketch references do not expose explicit motion duration, easing, spring-response, damping, stiffness, velocity, timing-curve, or bezier values that can be mapped as exact source-backed Liquid Glass motion tokens.

The approved B.6 source audit therefore left `AppleMotionTokens` unresolved and blocked Gate B completion rather than inventing values.

A separate authoritative Apple runtime reference has now been approved for motion.

## Approved Decision

Use documented SwiftUI spring semantics as the project motion runtime reference.

### Default spring reference

Apple documents `Animation.default` as a spring with:

- `response = 0.55`
- `dampingFraction = 1.0`
- `blendDuration = 0.0`

### Interactive spring reference

Apple documents:

`Animation.interactiveSpring(response:dampingFraction:blendDuration:)`

with defaults:

- `response = 0.15`
- `dampingFraction = 0.86`
- `blendDuration = 0.25`

## Fidelity Claim Boundary

The project MAY claim:

- `OFFICIAL_SWIFTUI_RUNTIME_REFERENCE = YES`
- the numeric values above are exact documented SwiftUI defaults;
- the runtime contract is intentionally shared across supported platforms.

The project MUST NOT claim:

- `EXACT_INTERNAL_LIQUID_GLASS_MOTION = YES`;
- that these values are undocumented internal iOS 27 or macOS 27 Liquid Glass implementation parameters;
- that every Apple system component uses exactly these presets in every interaction.

The accepted claim is:

`EXACT_INTERNAL_LIQUID_GLASS_MOTION = NO`

## Why This Is a Deviation

Visual Foundation 2.A normally requires exact values from the supplied Apple UI Kit source.

Motion is different because the supplied Sketch source does not contain explicit usable motion values.

Rather than guessing, measuring video approximately, or silently inventing values, this deviation uses exact values from official Apple SwiftUI runtime documentation and records the claim boundary explicitly.

## Cross-Platform Contract

Visual family mapping remains unchanged:

- Android and iOS use the iOS 27 visual family.
- Windows, Linux, and macOS use the macOS 27 visual family.

The approved SwiftUI motion presets are project-wide Apple-runtime references and may be reproduced on all supported platforms.

Platform rendering implementations may differ technically, but the requested spring parameter contract must remain the same unless a later approved renderer-specific deviation is required.

## Accessibility Contract

Apple Human Interface Guidelines state that system motion can adapt to accessibility settings and that Liquid Glass effects can change when motion is reduced.

Therefore custom motion must expose a Reduce Motion policy.

The initial Gate B.6C contract SHALL represent accessibility policy explicitly. It SHALL NOT silently run full spring motion when the project receives a reduce-motion signal.

The exact renderer integration for platform accessibility APIs belongs to later rendering/application gates unless already required by an existing foundation interface.

## Rejected Alternatives

### Keep Gate B blocked indefinitely

Rejected because an authoritative Apple runtime motion reference exists and the project needs an explicit, reviewable contract to continue.

### Infer internal Liquid Glass timing from video

Rejected because frame/video measurement is approximate and conflicts with the no-guessing fidelity contract.

### Invent custom durations/easing

Rejected because it would be an undocumented visual approximation.

## Official Apple References

Primary sources:

- Apple Developer Documentation — `Animation.default`
- Apple Developer Documentation — `interactiveSpring(response:dampingFraction:blendDuration:)`
- Apple Developer Documentation — `spring(response:dampingFraction:blendDuration:)`
- Apple Human Interface Guidelines — Motion
- Apple Developer Documentation — Adopting Liquid Glass

Verified on 2026-08-15.

## Governance

This decision resolves the **source-choice blocker** for B.6C only.

It does not itself make B.6C GREEN and does not make Gate B complete.

B.6C still requires RED -> GREEN implementation and fresh verification.

Until that implementation passes:

- `AppleMotionTokens` remains unresolved;
- `AppleVisualThemeData` remains unresolved;
- Gate B remains incomplete;
- Gate C remains blocked;
- Task 2.9 remains blocked.
