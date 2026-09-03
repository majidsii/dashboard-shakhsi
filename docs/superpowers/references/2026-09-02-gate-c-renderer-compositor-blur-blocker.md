# Gate C Renderer-Compositor Blur Blocker

**Date:** 2026-09-02
**Status:** BLOCKED
**Task:** Visual Foundation 2.A — Gate C — Task 6
**First affected tuple:** ios27 / light / smallControl / idle

## Measured RED

Golden:

    test/goldens/apple/ios27/light/small-control.png

Focused test result:

    Pixel test failed, 61.33%, 5262px diff detected.

The fixture provenance is already verified separately:

    APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS
    SELF_REFERENCE_GOLDENS=NONE

Therefore this is a renderer mismatch rather than a missing-source or
provenance failure.

## Locked source recipe evidence

The source-backed recipe contains Apple Custom Glass:

    style.blurs[0].isCustomGlass = 1
    style.blurs[0].isEnabled = true
    style.blurs[0].type = 4
    style.blurs[0].radius = 6
    style.blurs[0].saturation = 2
    style.blurs[0].brightness = 1
    style.blurs[0].distortion = 0.4
    style.blurs[0].depth = 0.8
    style.blurs[0].chromaticAberrationMultiplier = 0
    style.blurs[0].skipLightingEffects = true

Source style:

    Liquid Glass/Light/Regular - Small

Shared style ID:

    7DD2EB52-8E2A-4EC4-90B1-CB7985FF3549

## Renderer semantic mismatch

Sketch exposes the Glass value as a blur `radius`.

Flutter `dart:ui` ImageFilter.blur consumes `sigmaX` and `sigmaY`, defined as
the standard deviation of a Gaussian kernel.

No source-backed or official renderer evidence currently establishes an exact
conversion between:

    Sketch Glass blur radius

and:

    Flutter/Skia Gaussian sigma

Therefore none of the following conversions are approved:

    sigma = radius
    sigma = radius / 2
    sigma = radius * arbitraryMultiplier

`sourceBlurRadiusToSigma()` must not be implemented until exact conversion
semantics are established or the approved measured-deviation process permits
a renderer-specific deviation.

## Additional source-backed layers

The recipe also contains enabled source fills and source shadows.

Those fields remain available for later standard Flutter composition, but they
do not resolve the Glass blur semantic mismatch.

No compensating fill, shadow, border, opacity, radius, or other magic constant
may be introduced to conceal this blocker.

## Decision

Per Task 6:

    STANDARD_RENDERER_GOLDEN=RED
    FIRST_RENDERER_COMPOSITOR_BLOCKER=SKETCH_GLASS_RADIUS_TO_FLUTTER_SIGMA
    ARBITRARY_BLUR_CONVERSION=FORBIDDEN
    SHADER_PRESENT=NO
    COMMIT=NO

Stop Task 6 standard-renderer implementation here and proceed only through the
plan's measured-deviation / renderer-compositor decision path.

---

## Task 8 measured renderer matrix

The complete required golden matrix was executed after standard source-backed
composition was exhausted.

Result:

    STANDARD_FLUTTER_COMPOSITION_ACCEPTED=NO
    GATE_C_RENDERER_COMPOSITOR_BLOCKED=YES
    SHADER_CREATED=NO

Measured deltas:

| Tuple | Pixel delta |
|---|---:|
| ios27/light/smallControl | 61.33%, 5262px |
| ios27/dark/smallControl | 68.90%, 5912px |
| ios27/light/mediumSurface | 98.24%, 192780px |
| ios27/dark/mediumSurface | 98.11%, 196324px |
| macos27/light/smallControl | 61.63%, 5288px |
| macos27/dark/smallControl | 69.22%, 5939px |
| macos27/light/mediumSurface | 98.11%, 196324px |
| macos27/dark/mediumSurface | 98.11%, 196324px |
| macos27/light/overGlassControl | 100.00%, 10240px |
| macos27/dark/overGlassControl | 100.00%, 10240px |

## Interpretation

The mismatch is reproducible across all required source-backed fixtures.

Small control variants show partial renderer parity but fail pixel equivalence.

Medium surface and over-glass variants demonstrate that standard Flutter
composition cannot reproduce the Apple source glass material semantics.

The unresolved renderer semantic remains:

    Sketch Custom Glass radius
                |
                v
    Flutter/Skia ImageFilter Gaussian sigma

No approved conversion exists.

No shader, arbitrary sigma conversion, compensating opacity, fill, shadow,
border, or magic constant has been introduced.

Per Task 8 decision path execution stops here pending an explicit renderer
deviation decision.
