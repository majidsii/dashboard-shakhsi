# Gate C Custom Renderer Decision

**Date:** 2026-09-03  
**Status:** APPROVED FOR DESIGN PHASE  
**Task:** Visual Foundation 2.A — Gate C — Renderer Compositor Decision

## Context

Standard Flutter composition was evaluated against locked Apple source-backed Liquid Glass goldens.

Result:

    STANDARD_FLUTTER_COMPOSITION_ACCEPTED=NO
    GATE_C_RENDERER_COMPOSITOR_BLOCKED=YES

The blocker is a renderer semantic mismatch between:

    Sketch Custom Glass radius

and:

    Flutter/Skia ImageFilter Gaussian sigma

No exact source-backed conversion exists.

## Decision

The project will not accept a permanent visual deviation through standard Flutter composition.

The target path is:

    CUSTOM_LIQUID_GLASS_RENDERER

The public widget contract remains:

    AppleLiquidGlass

Rendering strategy:

    AppleLiquidGlass
            |
            v
    AppleGlassRenderStrategy
            |
            +----------------+
            |                |
            v                v
 Standard Flutter     Custom Glass Renderer

Custom renderer responsibilities:

- sampled background input
- advanced blur behavior
- saturation adaptation
- brightness adaptation
- distortion
- depth/light response

## Constraints

Forbidden until separately approved:

- arbitrary blur radius conversion
- magic opacity compensation
- fake shadow compensation
- shader creation without design approval
- replacing source-backed fixtures

## Prototype Requirement

First prototype target:

    ios27/light/smallControl

Current baseline:

    61.33%, 5262px diff

The prototype must demonstrate deterministic improvement before production integration.

## Next Phase

Only create renderer design.

Do not create production shader code until:

- shader inputs are defined;
- renderer lifecycle is defined;
- deviation boundaries are documented;
- golden comparison remains active.
