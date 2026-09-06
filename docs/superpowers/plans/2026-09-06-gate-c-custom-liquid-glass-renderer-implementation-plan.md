# Gate C --- Custom Liquid Glass Renderer Implementation Plan

**Date:** 2026-09-06

**Goal:** Implement a production-grade, source-backed Apple Liquid Glass
renderer.

## Architecture

The public `AppleLiquidGlass` API remains backend agnostic.

The architecture separates: - semantic recipe selection - runtime
backend capability detection - custom rendering execution

Pipeline:

AppleLiquidGlass → AppleGlassRenderStrategyResolver →
AppleCustomGlassRenderer → AppleCustomGlassCompositor → BackdropFilter →
ImageFilter.shader(FragmentShader)

## Global Constraints

-   Apple source goldens are immutable acceptance authority.
-   Never weaken provenance checks.
-   Never replace Apple references with Flutter generated output.
-   Never use fake blur approximation.
-   Never use arbitrary sigma calculations.
-   Never silently fallback from Custom Glass to standard glass.
-   Runtime capability must use `ImageFilter.isShaderFilterSupported`.

## Implementation Tasks

### Task 1 --- Separate semantic strategy and backend capability

Create a clear boundary:

`AppleGlassRenderStrategyResolver`

Responsibilities: - Decide whether recipe requires Custom Glass. - Never
decide GPU capability.

`AppleGlassBackendResolver`

Responsibilities: - Decide whether runtime backend can execute Custom
Glass. - Return explicit fidelity blocker when unavailable.

Acceptance: - Custom recipe + supported backend → Custom renderer. -
Custom recipe + unsupported backend → explicit unsupported state. -
Standard recipe → standard renderer.

### Task 2 --- Implement shader lifecycle

Create:

`shaders/apple_liquid_glass.frag`

Requirements: - FragmentProgram loaded once. - No shader loading inside
build or paint. - Cached lifecycle. - Explicit failure state.

### Task 3 --- Implement Impeller filter pipeline

Use:

-   BackdropFilter
-   ImageFilter.shader
-   FragmentShader

Forbidden: - Scene.toImage - RenderRepaintBoundary capture - Screenshot
rendering - Visual approximation fallback

### Task 4 --- Validation

Run:

-   Strategy tests
-   Backend capability tests
-   Shader contract tests
-   Apple golden provenance tests

Completion requires:

GATE_C_COMPLETE=YES

Only after: - shader backend exists - golden validation passes -
performance checks pass - no silent degradation exists
