# Gate C — Custom Liquid Glass Renderer Design

**Date:** 2026-09-06
**Status:** APPROVED DESIGN
**Boundary:** Visual Foundation 2.A — Gate C
**Parent decision:** `docs/superpowers/references/2026-09-03-gate-c-custom-renderer-decision.md`
**Measured blocker:** `docs/superpowers/references/2026-09-02-gate-c-renderer-compositor-blur-blocker.md`
**Impeller contract:** `docs/superpowers/references/2026-09-06-gate-c-impeller-backdrop-filter-contract.md`

---

## 1. Goal

Build a production-grade, source-backed Apple Liquid Glass renderer for a professional
cross-platform application that is expected to compete with high-quality native products.

The renderer must not trade product quality for implementation convenience.

Decision priority:

1. visual fidelity;
2. correct architecture;
3. performance;
4. reliability;
5. cross-platform capability;
6. maintainability;
7. implementation speed.

The public application API remains:

~~~dart
AppleLiquidGlass
~~~

Feature code must never know which internal renderer backend is active.

---

## 2. Product-quality contract

This renderer is not an MVP approximation.

The system must not choose weaker visual behavior merely because it is simpler.

The following are not acceptable shortcuts:

- approximate Apple glass;
- hand-tuned blur values;
- arbitrary visual compensation;
- silent renderer degradation;
- fake visual fallback;
- replacing source goldens;
- weakening provenance checks;
- accepting large visual deviations because the renderer is difficult to reproduce;
- removing source-backed effects to make implementation easier.

If a required platform does not yet have a backend capable of satisfying the approved
fidelity contract, that platform remains fidelity-blocked.

Unsupported means:

~~~text
required fidelity backend unavailable
~~~

It does not mean:

~~~text
render something that looks approximately similar
~~~

---

## 3. Existing evidence

Standard Flutter composition has already been measured against the locked Apple
source-backed golden matrix.

Result:

~~~text
STANDARD_FLUTTER_COMPOSITION_ACCEPTED=NO
GATE_C_RENDERER_COMPOSITOR_BLOCKED=YES
~~~

First affected target:

~~~text
ios27 / light / smallControl / idle
~~~

Measured baseline:

~~~text
61.33% pixel mismatch
5262 differing pixels
~~~

The complete required matrix also demonstrates deterministic mismatch for:

- iOS light/dark small controls;
- iOS light/dark medium surfaces;
- macOS light/dark small controls;
- macOS light/dark medium surfaces;
- macOS light/dark over-glass controls.

The first unresolved renderer semantic was:

~~~text
Sketch Custom Glass radius
        !=
Flutter/Skia Gaussian sigma
~~~

No exact source-backed radius-to-sigma conversion has been established.

Therefore arbitrary mappings remain forbidden.

---

## 4. Architectural direction

The approved target is a source-backed multi-backend renderer.

~~~text
AppleLiquidGlass
        |
        v
AppleLiquidGlassRecipeResolver
        |
        v
AppleGlassRenderStrategyResolver
        |
        +--------------------------------+
        |                                |
        v                                v
StandardGlassRenderer          AppleCustomGlassRenderer
                                        |
                                        v
                           AppleGlassBackendResolver
                                        |
                         +--------------+--------------+
                         |                             |
                         v                             v
              ImpellerGlassBackend          Future Fidelity Backend
                         |
                         v
                  exact geometry clip
                         |
                         v
                    BackdropFilter
                         |
                         v
            ImageFilter.shader(FragmentShader)
                         |
                         v
                 hybrid composition
                         |
                         v
                       child
~~~

The architecture must permit additional fidelity backends later without changing feature
widgets or the public `AppleLiquidGlass` contract.

---

## 5. Public API boundary

Feature code continues to use:

~~~dart
AppleLiquidGlass(
  theme: theme,
  role: role,
  state: state,
  child: child,
)
~~~

Renderer implementation details must remain internal.

The public widget must not expose parameters such as:

~~~text
sigma
shader
rendererBackend
blurMultiplier
distortionOverride
samplingRadius
lightingMultiplier
opacityCompensation
depthCompensation
~~~

Feature widgets consume Apple semantic roles rather than compositor controls.

---

## 6. Recipe authority

`AppleLiquidGlassRecipe` remains the visual source input to rendering.

The renderer must not bypass the recipe and independently inspect unrelated generated
style tables.

The recipe contains:

- family;
- brightness;
- glass role;
- control state;
- source IDs;
- source names;
- source values;
- role mapping evidence.

The recipe describes Apple source semantics.

It does not describe runtime platform policy.

---

## 7. Source-backed strategy selection

`AppleGlassRenderStrategyResolver` chooses renderer strategy from source evidence.

A recipe containing:

~~~text
style.blurs[0].isCustomGlass == 1
style.blurs[0].isEnabled == true
~~~

must select the Custom Glass rendering path.

Renderer policy must not be manually embedded into generated Apple source data.

No family-name or platform-name guess is required to detect Custom Glass.

---

## 8. Standard renderer

`AppleStandardGlassRenderer` remains valid only when the required source material
semantics can be represented faithfully through standard Flutter composition.

It may use source-backed:

- clipping;
- fills;
- gradients;
- borders;
- rims;
- shadows;
- opacity;
- overlays.

It must not be treated as an automatic fallback for Custom Glass.

Forbidden behavior:

~~~text
Custom Glass required
        +
custom backend unavailable
        =
StandardGlassRenderer
~~~

unless a separate controlled source comparison proves equivalent fidelity for the exact
tuple.

---

## 9. Custom renderer

`AppleCustomGlassRenderer` owns Apple material behavior that standard Flutter
composition cannot reproduce faithfully.

Its responsibilities may include:

- backdrop interaction;
- advanced source material filtering;
- saturation response;
- brightness response;
- distortion;
- depth response;
- source lighting behavior;
- backdrop/material interaction.

It must consume documented source semantics rather than hand-tuned visual constants.

---

## 10. Runtime backend resolution

Semantic strategy selection and runtime backend selection are separate responsibilities.

~~~text
Apple Custom Glass recipe
        |
        v
AppleGlassBackendResolver
        |
        +-- approved shader filter supported
        |          |
        |          v
        |   AppleImpellerGlassBackend
        |
        +-- no approved backend
                   |
                   v
          explicit fidelity blocker
~~~

This separation allows:

- recipe data to stay source-backed;
- runtime capabilities to remain runtime concerns;
- future backends to be introduced cleanly;
- feature code to remain unchanged.

---

## 11. Runtime capability interface

Runtime rendering capability should be centralized behind a narrow interface.

Conceptually:

~~~dart
abstract interface class AppleGlassRendererCapabilities {
  bool get supportsShaderImageFilter;
}
~~~

Production capability resolution uses:

~~~dart
ImageFilter.isShaderFilterSupported
~~~

Tests must be able to substitute deterministic capability values.

`ImageFilter.isShaderFilterSupported` must not be scattered throughout unrelated
renderer classes.

---

## 12. Impeller backend

The first approved custom fidelity backend is:

~~~text
AppleImpellerGlassBackend
~~~

Its main rendering primitive is:

~~~dart
ImageFilter.shader(FragmentShader shader)
~~~

used through Flutter's backdrop filtering pipeline.

Primary flow:

~~~text
exact clip
    |
    v
BackdropFilter
    |
    v
ImageFilter.shader(FragmentShader)
    |
    v
engine-provided backdrop input
~~~

Flutter 3.44.6 exposes runtime support through:

~~~dart
ImageFilter.isShaderFilterSupported
~~~

The shader filter must only be constructed when this capability is available.

---

## 13. Unsupported backend behavior

When Custom Glass is required but no approved fidelity backend exists:

~~~text
Custom Glass required
        +
approved backend unavailable
        =
PLATFORM_FIDELITY_BLOCKED
~~~

The renderer must not silently switch to generic Gaussian blur.

It must not silently switch to an approximately similar material.

This state must remain:

- explicit;
- testable;
- visible to platform readiness verification.

A platform is not considered complete merely because the application launches.

---

## 14. No low-quality fallback

The backend resolver must never implement logic equivalent to:

~~~text
if bestRendererUnavailable:
    useSomethingThatLooksCloseEnough
~~~

The project rule is:

~~~text
if approvedFidelityRendererUnavailable:
    exposeFidelityBlocker
~~~

This is required because the application is intended to be a professional competitive
product rather than a simplified visual approximation.

---

## 15. Backdrop pipeline

The primary Custom Glass path uses Flutter's existing backdrop-filter pipeline.

~~~text
AppleCustomGlassRenderer
        |
        v
AppleCustomGlassCompositor
        |
        v
exact source-backed clip
        |
        v
BackdropFilter
        |
        v
ImageFilter.shader
        |
        v
FragmentShader
~~~

The filter receives the already-rendered backdrop from the engine.

---

## 16. No manual scene capture

The production Custom Glass path must not use continuous manual scene capture.

Forbidden primary mechanisms include:

~~~text
Scene.toImage
RenderRepaintBoundary.toImage
manual screenshot capture
frame-by-frame raster readback
continuous CPU image extraction
~~~

The renderer must avoid transferring rendered frame content back to CPU merely to
re-submit it to the GPU.

---

## 17. ImageFilter shader engine contract

Flutter's `ImageFilter.shader` has specific shader requirements.

The first float uniform must be compatible with input dimensions.

The shader must contain at least one image sampler.

Conceptually the shader begins with:

~~~glsl
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture_input;
~~~

Flutter supplies:

- filter input dimensions;
- filter input image sampler.

Project-defined uniforms follow engine-reserved inputs.

The project must not violate this ordering.

---

## 18. Shader asset

The intended application shader is:

~~~text
shaders/apple_liquid_glass.frag
~~~

It must be registered through Flutter's shader asset mechanism.

The shader must not be loaded as an ordinary image asset.

The shader must not be created until the implementation plan establishes the required
RED tests and infrastructure contracts.

This design authorizes the shader architecture.

It does not authorize arbitrary visual math.

---

## 19. FragmentProgram lifecycle

Shader program loading requires an explicit lifecycle.

Required model:

~~~text
shader asset
        |
        v
AppleLiquidGlassShaderProgramLoader
        |
        v
cached FragmentProgram
        |
        v
FragmentShader instance
        |
        v
source uniform binding
        |
        v
ImageFilter.shader
~~~

`FragmentProgram.fromAsset` must not be initiated repeatedly in build or paint hot paths.

Flutter already maintains an internal `FragmentProgram` registry, but project code must
still avoid unnecessary repeated load requests.

---

## 20. Shader program loader

Program loading should be hidden behind a dedicated component.

Conceptual responsibility:

~~~text
AppleLiquidGlassShaderProgramLoader
~~~

Responsibilities:

- own shader asset identity;
- initiate program loading;
- expose loading state;
- expose success;
- expose failure;
- reuse the loaded program;
- avoid render-loop asset loads.

The compositor must not contain unrelated asynchronous asset-loading logic.

---

## 21. Shader program states

The loader should distinguish at least:

~~~text
notLoaded
loading
ready
failed
~~~

A load failure must not result in silent visual downgrade.

Failure remains explicit.

Tests must exercise the failure path.

---

## 22. FragmentProgram reuse

`FragmentProgram` represents the compiled shader program and should be reused.

Program loading must not occur independently for every glass surface or frame.

The implementation should rely on both:

- explicit project lifecycle ownership;
- Flutter's internal shader program cache.

Correctness must remain clear even though Flutter performs internal caching.

---

## 23. FragmentShader ownership

A `FragmentShader` carries mutable uniform state.

One mutable shader instance must not be shared unsafely across unrelated simultaneous
glass surfaces with different recipe values.

The implementation plan must explicitly decide whether shader instances are:

- per renderer instance;
- per glass instance;
- safely pooled;
- reconstructed from a cached program.

Premature optimization must not compromise correctness.

---

## 24. Source semantic uniforms

Project-defined uniforms may only represent:

1. engine-required values; or
2. documented Apple source semantics.

The first prototype recipe contains semantics including:

~~~text
style.blurs[0].radius = 6
style.blurs[0].saturation = 2
style.blurs[0].brightness = 1
style.blurs[0].distortion = 0.4
style.blurs[0].depth = 0.8
style.blurs[0].center = {0.5, 0.5}
style.blurs[0].chromaticAberrationMultiplier = 0
style.blurs[0].skipLightingEffects = true
style.blurs[0].extraSamplingRegion = 0
~~~

It also contains multiple source-backed fill and shadow records.

---

## 25. Source value versus algorithm

A known source value does not automatically prove the mathematical renderer behavior.

For example:

~~~text
distortion = 0.4
~~~

is source-backed.

A custom UV distortion formula interpreting `0.4` is not automatically source-backed.

Therefore:

~~~text
source semantic known
        !=
renderer algorithm proven
~~~

Algorithmic mappings must be isolated and measured against locked Apple source output.

---

## 26. Radius rule

No arbitrary conversion between Apple Custom Glass radius and Flutter Gaussian sigma is
authorized.

Forbidden production mappings include:

~~~text
sigma = radius

sigma = radius / 2

sigma = radius * arbitraryMultiplier
~~~

Apple Custom Glass `radius` remains an Apple semantic.

If it participates in a shader algorithm, the algorithm must be separately documented
and validated.

The renderer must not disguise an arbitrary Gaussian approximation as Apple Custom Glass.

---

## 27. No magic visual uniforms

Shader parameters must not be introduced merely because tuning them makes output look
closer.

Examples of forbidden unsupported concepts:

~~~text
u_magicBlur
u_visualCompensation
u_similarityBoost
u_fakeDepth
u_extraOpacity
u_tunedBrightness
u_magicLighting
~~~

A parameter requires either:

- source evidence;
- engine contract evidence;
- or separately approved renderer semantics.

---

## 28. Hybrid renderer

The custom fragment shader should remain as narrow as fidelity permits.

The existence of a shader does not justify implementing the entire material inside one
large shader.

Backdrop-dependent semantics belong in the custom filter path.

Source-backed layers that Flutter can reproduce exactly should remain in regular Flutter
composition where appropriate.

Potential standard layers include:

- corner clipping;
- fills;
- gradients;
- external shadows;
- borders;
- rims;
- highlights;
- content.

This improves:

- isolation;
- testability;
- maintainability;
- profiling;
- debugging;
- renderer evolution.

---

## 29. Full shader compositor alternative

A full-material shader remains possible only if measured evidence later proves that hybrid
composition cannot reproduce required layer interactions.

It is not the initial architecture.

Moving a source-backed layer into the shader requires evidence that the hybrid path cannot
reproduce the source semantics.

This prevents unnecessary shader complexity.

---

## 30. Composition order

Layer composition must be deterministic and evidence-driven.

Initial conceptual structure:

~~~text
external source-backed effects
        |
        +-- external shadows
        |
        v
exact source-backed shape clip
        |
        +-- custom backdrop filter
        |
        +-- source-backed fill layers
        |
        +-- source-backed rim/highlight layers
        |
        +-- content child
~~~

The implementation plan must verify source layering before permanently fixing final order.

Layers must not be rearranged simply because another order looks subjectively better.

---

## 31. Exact clipping

Backdrop filtering must be constrained to the intended glass region.

Unbounded filtering may:

- alter source semantics;
- increase sampled area;
- increase GPU cost;
- increase offscreen allocation;
- affect surrounding pixels;
- damage golden determinism.

The filter region must use approved source-backed geometry.

---

## 32. Filter region performance

The renderer must not use full-screen filtering for small controls simply because it is
easier.

Performance design must consider:

- filtered pixel area;
- offscreen render target size;
- overdraw;
- multiple simultaneous glass instances;
- desktop window dimensions;
- animation frequency;
- mobile GPU cost;
- memory bandwidth.

Filter bounds should be as tight as source semantics permit.

---

## 33. First prototype

The first visual prototype remains:

~~~text
ios27 / light / smallControl / idle
~~~

Locked golden:

~~~text
test/goldens/apple/ios27/light/small-control.png
~~~

Current baseline:

~~~text
61.33% pixel mismatch
5262 differing pixels
~~~

This baseline remains the comparison point.

---

## 34. Identity shader milestone

The first shader implementation is infrastructure validation.

It must not claim Apple Liquid Glass fidelity.

The identity shader exists to prove:

- shader asset registration;
- FragmentProgram loading;
- program lifecycle;
- FragmentShader creation;
- uniform contract;
- backdrop input;
- `ImageFilter.shader`;
- exact clipping;
- backend capability detection;
- deterministic golden execution.

Conceptually:

~~~glsl
void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  frag_color = texture(u_texture_input, uv);
}
~~~

The exact implementation must satisfy Flutter's runtime shader contract.

---

## 35. Identity shader acceptance

The identity shader milestone is successful when the infrastructure operates
deterministically.

It does not need to improve the Apple golden yet.

Its job is to establish that the pipeline itself works.

The implementation plan must clearly distinguish:

~~~text
PIPELINE_VALID
~~~

from:

~~~text
APPLE_GLASS_FIDELITY_VALID
~~~

---

## 36. Semantic reconstruction order

After the identity pipeline is proven, visual semantics should be introduced one at a
time whenever possible.

Recommended sequence:

~~~text
1. identity shader path
2. backdrop sampler validation
3. exact clipping
4. source-backed Flutter fill layers
5. saturation semantic
6. brightness semantic
7. distortion semantic
8. depth semantic
9. required lighting behavior
10. remaining source interactions
~~~

Each step must identify exactly what semantic was introduced.

---

## 37. Controlled measurements

Every meaningful renderer iteration records:

~~~text
fixture
previous mismatch percentage
previous differing-pixel count
new mismatch percentage
new differing-pixel count
semantic introduced
~~~

This creates an evidence trail rather than subjective visual tuning.

---

## 38. First visual improvement gate

Once Apple visual semantics begin, the first prototype must show deterministic improvement
over:

~~~text
61.33%
5262 differing pixels
~~~

Intermediate improvement means:

~~~text
new mismatch percentage < 61.33%
new differing-pixel count < 5262
~~~

Both must improve.

This is only an intermediate milestone.

It is not Gate C completion.

---

## 39. Determinism

A prototype improvement must reproduce across repeated runs.

A single favorable golden run is insufficient.

If rendering results are nondeterministic, the source of nondeterminism must be
investigated before accepting measurements.

---

## 40. Golden authority

Locked Apple source-derived fixtures remain the visual authority.

The renderer must never:

- replace them with Flutter-generated output;
- update them merely because tests fail;
- swap light/dark assignments;
- rescale them to simplify rendering;
- lower provenance validation;
- weaken the verifier;
- silently increase accepted tolerance.

The renderer must conform to the source authority.

The source authority must not conform to the renderer.

---

## 41. Required golden matrix

Final fidelity validation includes:

~~~text
ios27/light/small-control.png
ios27/dark/small-control.png
ios27/light/medium-surface.png
ios27/dark/medium-surface.png

macos27/light/small-control.png
macos27/dark/small-control.png
macos27/light/medium-surface.png
macos27/dark/medium-surface.png
macos27/light/over-glass-control.png
macos27/dark/over-glass-control.png
~~~

Passing the initial iOS light prototype is not sufficient to finish Gate C.

---

## 42. Task 4 protection

Existing locked source golden provenance remains independently verified by:

~~~text
tool/verify_apple_liquid_glass_golden_sources.py
~~~

Expected authority:

~~~text
APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS
SELF_REFERENCE_GOLDENS=NONE
~~~

Custom renderer development must not modify this contract to achieve green tests.

---

## 43. Backend abstraction

Custom rendering should use a narrow backend interface.

Conceptually:

~~~dart
abstract interface class AppleCustomGlassBackend {
  Widget build({
    required AppleLiquidGlassRecipe recipe,
    required Widget child,
  });
}
~~~

The first backend is:

~~~text
AppleImpellerGlassBackend
~~~

Additional implementations may be added later without changing feature code.

---

## 44. Backend resolver

Backend resolution remains internal.

~~~text
AppleCustomGlassRenderer
        |
        v
AppleGlassBackendResolver
        |
        +-- shader image filter supported
        |        |
        |        v
        | AppleImpellerGlassBackend
        |
        +-- unsupported
                 |
                 v
        PLATFORM_FIDELITY_BLOCKED
~~~

Tests must prove both branches.

---

## 45. Future fidelity backends

The architecture deliberately permits future backends.

Potential future categories may include:

- future Flutter image-filter capabilities;
- platform-specific GPU integrations;
- native compositor integrations;
- another Impeller-based rendering path;
- specialized desktop rendering backend.

These are extension points, not pre-approved implementations.

A backend must still pass the same locked source-golden authority.

---

## 46. Cross-platform product requirement

The application is expected to operate as a professional cross-platform product.

A platform-specific rendering limitation must not automatically reduce product visual
quality.

Instead:

~~~text
platform
    |
    v
required AppleVisualFamily
    |
    v
required Liquid Glass roles
    |
    v
approved backend exists?
    |
    +-- yes --> fidelity verification
    |
    +-- no  --> platform remains fidelity-blocked
~~~

This keeps the architecture capable of adding the correct backend instead of permanently
accepting a weak fallback.

---

## 47. Multiple glass instances

The renderer must support multiple simultaneous Liquid Glass surfaces.

Requirements include:

- shared FragmentProgram reuse;
- independent per-instance uniforms;
- no accidental mutable shader sharing;
- correct backdrop position for each surface;
- bounded filtering per instance;
- stable performance.

One glass instance must not corrupt another instance's shader state.

---

## 48. Performance contract

The renderer must be appropriate for real production workloads.

It must avoid:

- CPU frame readback;
- repeated shader asset loads;
- unnecessary full-screen filtering;
- excessive offscreen allocation;
- unnecessary saveLayer expansion;
- unnecessary object creation in hot paint paths;
- uncontrolled shader instance creation;
- excessive rebuilding;
- excessive repainting.

Performance optimization must never alter source semantics silently.

---

## 49. Performance verification

Before Gate C completion, implementation must measure or verify:

- shader asset load frequency;
- FragmentProgram reuse;
- FragmentShader lifecycle;
- filter bounds;
- offscreen filter size;
- rebuild behavior;
- repaint behavior;
- multiple simultaneous glass surfaces;
- mobile GPU behavior;
- desktop GPU behavior on supported targets;
- frame stability.

The professional product target requires both visual fidelity and runtime performance.

---

## 50. Failure handling

The following states require deterministic behavior:

~~~text
shader image filter unsupported
shader asset missing
FragmentProgram load failure
invalid FragmentShader contract
missing required source semantic
invalid source recipe
unsupported renderer backend
invalid uniform binding
~~~

None of these conditions may silently invoke a lower-quality approximation.

---

## 51. Renderer deviation policy

Production accepted renderer deviations remain:

~~~text
ZERO
~~~

A measured mismatch can be recorded as a blocker.

A documented blocker is not automatically an accepted production deviation.

Any permanent accepted deviation requires a separate explicit approval.

---

## 52. Existing scaffold

Current worktree renderer scaffolding includes:

~~~text
AppleGlassRenderStrategy
AppleGlassRenderStrategyResolver
AppleStandardGlassRenderer
AppleCustomGlassRenderer
AppleGlassCompositor
AppleStandardGlassCompositor
AppleCustomGlassCompositor
~~~

These boundaries are consistent with the approved direction.

Current pass-through implementations must not be mistaken for completed rendering.

---

## 53. Current strategy behavior

Current strategy detection uses source semantics:

~~~text
style.blurs[0].isCustomGlass == 1
style.blurs[0].isEnabled == true
~~~

and routes enabled Custom Glass to:

~~~text
AppleCustomGlassRenderer
~~~

This source-driven routing direction is retained.

---

## 54. Strategy tests

Tests must verify:

- enabled Custom Glass selects custom strategy;
- non-Custom-Glass selects standard strategy;
- routing derives from source values;
- no manually assigned renderer-policy field is required;
- feature API remains independent from renderer backend.

---

## 55. Capability tests

Tests must verify:

- supported shader-image-filter capability selects Impeller backend;
- unsupported capability does not silently select standard fallback;
- capabilities are injectable or otherwise deterministic in tests;
- runtime capability lookup remains centralized.

---

## 56. Program loader tests

Tests must verify:

- correct shader asset identity;
- load starts through loader lifecycle;
- ready state exposes program;
- repeated usage reuses the program;
- load failure remains explicit;
- renderer does not hide failure by falling back visually.

---

## 57. Shader contract tests

Tests must verify:

- required engine input uniforms exist;
- input dimensions use correct ordering;
- required sampler contract exists;
- project semantic uniforms are deterministic;
- unsupported semantic mappings are not guessed.

Where practical, typed semantic adapters should replace scattered direct string-map access
inside renderer internals.

---

## 58. Golden tests

Golden tests remain controlled by:

- Apple family;
- brightness;
- glass role;
- control state;
- logical size;
- DPR;
- controlled background;
- locked source fixture.

Renderer implementation must adapt to this authority.

---

## 59. Identity pipeline implementation phase

The first implementation phase that touches the shader must contain no unsupported Apple
visual tuning.

Its purpose is to prove:

~~~text
BackdropFilter
+
ImageFilter.shader
+
FragmentProgram lifecycle
+
FragmentShader lifecycle
+
clip bounds
+
golden harness
~~~

before reverse-engineering material semantics.

---

## 60. Semantic implementation phase

After infrastructure works, Apple semantics are added individually.

For each semantic:

~~~text
RED measurement
        |
        v
one documented semantic mapping
        |
        v
focused golden run
        |
        v
record delta
~~~

If evidence does not improve fidelity, the hypothesis is rejected rather than compensated
with additional magic constants.

---

## 61. Saturation

The source provides saturation values.

The numerical value itself is source-backed.

Its exact shader interpretation must still be measured.

The implementation must not assume an arbitrary color-matrix interpretation without
evidence.

---

## 62. Brightness

The source provides brightness semantics.

The value itself is source-backed.

The renderer must establish whether it represents:

- multiplicative luminance;
- additive response;
- another material-specific operation.

It must not guess solely based on visual preference.

---

## 63. Distortion

The source contains distortion semantics.

For the first prototype:

~~~text
distortion = 0.4
~~~

The value is authoritative.

The distortion algorithm is not yet authoritative.

Potential UV displacement behavior requires measurement before production acceptance.

---

## 64. Depth

The source contains depth semantics.

For the first prototype:

~~~text
depth = 0.8
~~~

Depth may participate in:

- spatial material response;
- lighting;
- refraction;
- other custom-glass behavior.

The algorithm must be determined by evidence rather than arbitrary mapping.

---

## 65. Lighting behavior

The recipe contains:

~~~text
skipLightingEffects = true
~~~

This source value must be respected.

The renderer must not add decorative lighting merely because it visually resembles common
Liquid Glass examples.

Where lighting is disabled by source semantics, the renderer must not invent it.

---

## 66. Chromatic aberration

The first prototype recipe contains:

~~~text
chromaticAberrationMultiplier = 0
~~~

The renderer must not add chromatic aberration to that tuple.

Future tuples with non-zero source values require separate measured mapping.

---

## 67. Fill layers

The source recipe contains multiple enabled fill records with:

- exact colors;
- alpha values;
- blend modes;
- opacity;
- fill type;
- gradient metadata.

These layers should remain source-driven.

They must not be collapsed into a single hand-tuned translucent color unless proven
equivalent.

---

## 68. Shadows

The first prototype contains multiple source-backed shadows.

The renderer must preserve their individual semantics where they materially affect output.

It must not replace the complete source shadow stack with a generic single shadow simply
to reduce implementation complexity.

If Flutter cannot represent a source blend interaction accurately, that limitation must be
measured.

---

## 69. Blend modes

Source fill and shadow records include blend-mode information.

Blend semantics must be mapped deliberately.

Unsupported or ambiguous source blend behavior must remain a blocker until a defensible
renderer mapping exists.

The implementation must not silently replace an unsupported blend mode with `srcOver`
because it is convenient.

---

## 70. Corners

The source recipe includes:

~~~text
style.corners.prefersConcentric
style.corners.smoothing
style.corners.style
~~~

The exact shape semantics must be respected.

Rounded clipping must not assume generic Flutter circular corner behavior if source
evidence requires a different curve.

Corner fidelity is part of the material result.

---

## 71. Source center

Custom Glass source data includes:

~~~text
style.blurs[0].center
~~~

This must remain available to shader semantics.

It must not be discarded merely because the first static prototype appears centered.

---

## 72. Extra sampling region

The source exposes:

~~~text
style.blurs[0].extraSamplingRegion
~~~

Its renderer effect must be understood before introducing additional sampling beyond
normal bounds.

No arbitrary texture-padding multiplier is authorized.

---

## 73. Professional-product decision rule

Every renderer decision should be evaluated with this question:

~~~text
If this application had to compete visually and technically with the best
products in its category, would this still be the implementation we choose?
~~~

If the answer is no and the only justification is easier implementation, the shortcut is
rejected.

---

## 74. Implementation phases

Implementation should proceed as:

~~~text
Phase A
Renderer strategy and capability contracts

Phase B
Backend resolver and explicit unsupported state

Phase C
Shader program loader and lifecycle

Phase D
Identity ImageFilter shader

Phase E
Backdrop and clipping validation

Phase F
ios27/light/smallControl source-backed prototype

Phase G
Semantic-by-semantic fidelity reconstruction

Phase H
Full iOS/macOS golden matrix

Phase I
Performance and lifecycle verification

Phase J
Full Gate C verification
~~~

Every implementation phase follows RED → GREEN.

---

## 75. Phase A

Phase A introduces architectural contracts only.

It should establish:

- backend interface;
- runtime capability interface;
- backend resolver;
- unsupported fidelity state;
- strategy tests;
- capability tests.

No visual shader algorithm is introduced.

---

## 76. Phase B

Phase B establishes backend selection behavior.

Supported runtime:

~~~text
Custom Glass
    ->
AppleImpellerGlassBackend
~~~

Unsupported runtime:

~~~text
Custom Glass
    ->
PLATFORM_FIDELITY_BLOCKED
~~~

No generic visual fallback is introduced.

---

## 77. Phase C

Phase C introduces program lifecycle.

It establishes:

- shader asset registration;
- shader program loader;
- program readiness state;
- program failure state;
- FragmentProgram reuse;
- shader-instance ownership design.

No Apple material math is required yet.

---

## 78. Phase D

Phase D creates the identity shader.

The goal is infrastructure proof.

The output should preserve backdrop input as closely as the filter contract allows.

No saturation, brightness, distortion or depth behavior is introduced in this phase.

---

## 79. Phase E

Phase E verifies:

- correct backdrop content reaches the shader;
- engine dimensions are correct;
- clip bounds are correct;
- child composition remains correct;
- filter region remains bounded.

Only after these pass should material reconstruction begin.

---

## 80. Phase F

Phase F targets:

~~~text
ios27 / light / smallControl / idle
~~~

Source-backed semantics are introduced incrementally.

Each renderer change is compared to the same locked Apple fixture.

---

## 81. Phase G

Phase G reconstructs required material semantics one by one.

No semantic is implemented merely because it is commonly associated with Liquid Glass.

It must have source evidence.

No hidden visual compensation is allowed.

---

## 82. Phase H

Phase H expands from the first prototype to the complete required iOS/macOS matrix.

Any family/brightness/role failure remains a blocker.

No single fixture can approve the complete renderer.

---

## 83. Phase I

Phase I validates production runtime characteristics.

This includes:

- shader program reuse;
- shader allocation;
- multiple glass surfaces;
- filter bounds;
- frame cost;
- rebuild/repaint behavior;
- supported target platform behavior.

---

## 84. Phase J

Phase J runs the complete Gate C contract.

It includes:

- source generator freshness;
- source provenance verifier;
- recipe tests;
- resolver tests;
- strategy tests;
- capability tests;
- shader lifecycle tests;
- golden matrix;
- full test suite;
- analyzer;
- Linux debug build where required;
- diff checks;
- performance evidence.

---

## 85. Gate C completion

Gate C cannot be marked complete until:

1. source recipe generation remains fresh;
2. Task 4 golden provenance remains PASS;
3. source strategy selection is deterministic;
4. custom backend resolution is deterministic;
5. unsupported backends do not silently degrade;
6. shader lifecycle is explicit;
7. no manual frame capture is used;
8. no arbitrary radius-to-sigma conversion exists;
9. all visual constants are source-backed or engine-required;
10. source goldens remain unchanged;
11. required golden matrix satisfies the approved fidelity boundary;
12. production accepted renderer deviations remain zero;
13. performance verification passes;
14. full regression suite passes;
15. Flutter analyzer passes;
16. required builds pass;
17. `git diff --check` passes.

Until then:

~~~text
GATE_C_COMPLETE=NO
TASK_2_9=BLOCKED
~~~

---

## 86. Explicit non-goals

This design does not authorize:

- Material visible fallback;
- Fluent visible fallback;
- native-looking approximate fallback;
- generic Gaussian fallback for Custom Glass;
- manual screenshot sampling;
- frame CPU readback;
- arbitrary radius-to-sigma conversion;
- magic visual constants;
- source golden modification;
- source verifier weakening;
- production acceptance of visual deviations;
- Gate D work;
- feature-screen migration;
- Task 2.9 work.

---

## 87. Final architectural decision

The approved architecture is:

~~~text
SOURCE-BACKED MULTI-BACKEND LIQUID GLASS RENDERER
~~~

with:

~~~text
AppleImpellerGlassBackend
        |
        v
BackdropFilter
        |
        v
ImageFilter.shader(FragmentShader)
~~~

as the first custom fidelity backend.

The architecture is deliberately designed for a professional product expected to compete
with high-quality applications.

Implementation speed may improve engineering efficiency.

It must not reduce:

- fidelity;
- capability;
- performance expectations;
- reliability;
- cross-platform architecture quality;
- maintainability;
- long-term product quality.
