# Gate C Custom Renderer Decision

**Date:** 2026-09-03  
**Status:** APPROVED FOR DESIGN PHASE  
**Task:** Visual Foundation 2.A — Gate C — Renderer Compositor Decision

## Context

Standard Flutter composition was evaluated against locked Apple source-backed
Liquid Glass goldens.

The measured comparison produced:

    STANDARD_FLUTTER_COMPOSITION_ACCEPTED=NO
    GATE_C_RENDERER_COMPOSITOR_BLOCKED=YES

The blocker is not missing source data.

The blocker is a renderer semantic mismatch between:

    Sketch Custom Glass radius

and:

    Flutter/Skia ImageFilter Gaussian sigma

No exact source-backed conversion exists.

## Decision

The project will not accept a permanent visual deviation through standard
Flutter composition.

The target implementation path is:

    CUSTOM_LIQUID_GLASS_RENDERER

The renderer must preserve the existing public widget contract:

    AppleLiquidGlass

while allowing an internal rendering strategy switch.

## Rendering Strategy

The implementation will use a layered architecture:

    AppleLiquidGlass
            |
            v
    AppleGlassRenderStrategy
            |
            +--------------------+
            |                    |
            v                    v
Standard Flutter Renderer   Custom Glass Renderer

Standard composition remains valid for source-backed layers that can be
represented accurately.

Custom rendering is reserved for Apple Glass semantics that require:

- sampled background input;
- advanced blur kernel behavior;
- saturation adaptation;
- brightness adaptation;
- distortion;
- depth/light response.

## Constraints

The following remain forbidden until separately approved:

- arbitrary blur radius conversion;
- magic opacity compensation;
- fake shadow compensation;
- shader creation without implementation design;
- replacing source-backed fixtures.

## Prototype Requirement

Before production integration, a renderer prototype must prove improvement
against at least:

    ios27/light/smallControl

Current baseline:

    61.33%, 5262px diff

Prototype acceptance target:

    measured improvement with deterministic comparison.

## Next Phase

Create renderer prototype design only.

Do not create production shader code until:

- shader inputs are defined;
- renderer lifecycle is defined;
- deviation boundaries are documented;
- golden comparison remains active.
