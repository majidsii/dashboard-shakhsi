# Gate C Render Strategy Architecture

## Goal

Introduce a renderer abstraction for Apple Liquid Glass without changing the public widget contract.

## Public API

The application continues using:

    AppleLiquidGlass

No caller should know which renderer is active.

## Architecture

    AppleLiquidGlass
            |
            v
    AppleGlassRenderStrategyResolver
            |
            +----------------------+
            |                      |
            v                      v
 StandardGlassRenderer     CustomGlassRenderer

## Standard Renderer

Responsible for source-backed layers supported by Flutter:

- fills
- opacity
- borders
- corner radius
- shadows

## Custom Renderer

Responsible for Apple Glass semantics not represented by standard Flutter:

- background sampling
- advanced blur
- saturation adaptation
- brightness response
- distortion
- depth lighting

## Constraints

- No shader implementation yet.
- No arbitrary blur conversion.
- Golden comparison remains the acceptance gate.
- Renderer selection must be deterministic.

## First Prototype

Target:

    ios27/light/smallControl

Success criteria:

Improve baseline:

    61.33%, 5262px diff

without modifying source fixtures.
