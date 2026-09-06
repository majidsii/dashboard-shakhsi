# Gate C — Custom Liquid Glass Shader Parameter & Lifecycle Architecture

Date: 2026-09-06
Status: Approved design for implementation planning
Scope: Apple Visual Foundation 2.A — Gate C

## Product standard

This renderer is for a professional, production-grade application that must remain competitive with high-quality native products. Development convenience must not reduce visual fidelity, runtime reliability, performance, maintainability, or testability.

Any fallback, approximation, or deviation must be explicit, measurable, documented, testable, and justified by a real platform limitation or source ambiguity.

## Established evidence

The current Gate C work has already established:

- locked Apple-source goldens remain the visual authority;
- the public `AppleLiquidGlass` API remains stable;
- renderer selection is source-backed;
- enabled Apple Custom Glass selects the custom renderer path;
- unsupported shader-filter backends are represented explicitly;
- Flutter 3.44.6 exposes `ImageFilter.shader`;
- `flutter test --enable-impeller` executes the real Impeller path;
- an identity shader successfully runs through
  `AppleCustomGlassRenderer -> AppleCustomGlassCompositor -> BackdropFilter -> ImageFilter.shader -> Impeller`;
- the identity shader leaves the locked `ios27/light/smallControl` baseline at 61.33% mismatch and 5262 differing pixels.

The identity shader proves plumbing only. It is not accepted Liquid Glass fidelity.

## Architecture

Raw Apple source values must not be consumed ad hoc inside compositor or shader code.

```text
AppleLiquidGlassRecipe
        |
        v
AppleGlassShaderParameterResolver
        |
        v
AppleGlassShaderParameters
        |
        v
AppleCustomGlassFilter
        |
        v
FragmentShader uniforms
        |
        v
ImageFilter.shader
        |
        v
BackdropFilter / Impeller
```

## Typed parameter contract

Introduce immutable `AppleGlassShaderParameters` containing source-native semantics:

- `customGlassEnabled`
- `saturation`
- `brightness`
- `distortion`
- `depth`
- `chromaticAberration`
- `skipLightingEffects`
- `customGlassRadius`

`customGlassRadius` is retained as source evidence only. No `Apple radius -> Gaussian sigma` conversion is authorized until a defensible mapping is established.

## Parameter resolver

Introduce `AppleGlassShaderParameterResolver`.

Responsibilities:

1. Read only documented keys from `AppleLiquidGlassRecipe.sourceValues`.
2. Convert source numeric values to typed Dart values.
3. Reject missing, malformed, non-finite, or contradictory required values.
4. Preserve source-native numbers without arbitrary clamping.
5. Keep renderer calibration separate from source extraction.
6. Produce deterministic output for the same recipe.

It must not inspect widget state, inspect backend capability, create GPU objects, guess blur sigma, mutate source data, or normalize unknown values merely to simplify rendering.

## Source semantics vs renderer calibration

Source semantics are facts from the Apple representation, for example:

- saturation = 2
- brightness = 1
- distortion = 0.4
- depth = 0.8
- chromatic aberration = 0
- skip lighting effects = true

Renderer calibration is the mapping from those facts to shader mathematics. Calibration is allowed only when tied to a documented model, measured against locked Apple goldens, reproducible, and recorded as renderer behavior rather than rewritten source truth.

## Shader uniform contract

The Flutter engine-reserved contract remains first:

```glsl
uniform vec2 u_size;
uniform sampler2D u_texture_input;
```

Application uniforms come after engine-provided inputs.

Behavior must be introduced incrementally:

1. identity sampling;
2. saturation;
3. brightness;
4. distortion;
5. depth/lighting;
6. additional source-backed effects when justified.

`customGlassRadius` remains excluded from blur behavior until the radius mapping blocker is resolved.

## Shader lifecycle

`FragmentProgram.fromAsset` is internally cached by Flutter, so the app should not add a redundant program cache solely for performance.

The app does need an explicit prewarm/readiness layer so the first visible Liquid Glass surface does not flash an unfiltered child while the program loads.

Target lifecycle:

```text
App/Visual bootstrap
        |
        v
AppleGlassShaderPrewarmer
        |
        v
FragmentProgram.fromAsset(...)
        |
        v
program ready
        |
        +----------------------+
        |                      |
        v                      v
renderer A                 renderer B
FragmentShader             FragmentShader
instance                   instance
        |                      |
        v                      v
dispose on widget          dispose on widget
lifecycle end              lifecycle end
```

A `FragmentShader` contains mutable uniform state. Never share one mutable shader across simultaneous glass surfaces. Each active filter owns its own shader instance and disposes it with its widget lifecycle.

## Prewarm behavior

The custom glass program should be prewarmed before Liquid Glass surfaces are expected to appear.

Required behavior:

- successful prewarm makes the program available to custom glass filters;
- failed prewarm is surfaced explicitly;
- backend capability is checked before initialization;
- silent fallback to plain child rendering is not treated as equivalent fidelity.

The implementation plan must identify the narrowest existing bootstrap boundary that can guarantee readiness without unnecessarily delaying unrelated startup.

## Unsupported backend policy

For source recipes requiring Custom Glass:

- shader-filter supported -> custom renderer;
- shader-filter unsupported -> explicit unsupported/deviation path.

A later fallback is allowed only if it is named as a fallback, measured separately, never represented as equivalent to Impeller fidelity, and never used to justify changing Apple source goldens.

## Error handling

These must be explicit failures or states:

- shader asset missing;
- shader load/compile failure;
- invalid parameter extraction;
- unsupported shader-filter backend;
- invalid ImageFilter shader uniform contract;
- disposed-shader misuse.

Initialization failures should be captured at the lifecycle boundary and surfaced deterministically rather than thrown repeatedly from `build`.

## Testing strategy

### Unit tests

`AppleGlassShaderParameterResolver` must:

- extract all required source values;
- preserve exact source-native values;
- reject malformed required values;
- reject non-finite values;
- perform no radius-to-sigma conversion.

### Strategy tests

Keep coverage for:

- Custom Glass + shader support -> custom renderer;
- Custom Glass + no shader support -> explicit unsupported renderer;
- non-Custom-Glass -> standard renderer.

### Lifecycle tests

Prewarm layer:

- loads the expected asset;
- resolves readiness once;
- reports load failure;
- does not create mutable FragmentShader instances globally.

Filter lifecycle:

- creates its own FragmentShader;
- updates uniforms from typed parameters;
- disposes the shader.

### Impeller integration tests

Run with:

```bash
flutter test --enable-impeller
```

Prove:

- `ImageFilter.isShaderFilterSupported == true`;
- `BackdropFilter` uses `ImageFilter.shader`;
- shader asset loads and executes;
- no lifecycle exception occurs.

### Golden tests

Locked Apple goldens remain immutable.

Primary calibration fixture:

`ios27 / light / smallControl`

Current identity baseline:

- 61.33% mismatch;
- 5262 differing pixels.

After each meaningful shader milestone:

1. measure the primary fixture;
2. record the delta;
3. do not update the source golden;
4. run the full 10-fixture matrix before accepting the milestone.

## Calibration milestones

### Milestone 0 — Identity

Already proven. Purpose: validate Impeller plumbing only.

### Milestone 1 — Typed source parameters

No visual behavior change. Purpose: prove exact Apple-source-to-renderer data flow.

### Milestone 2 — Color response

Introduce source-backed saturation and brightness behavior. Document the mathematical model and remeasure the primary golden.

### Milestone 3 — Distortion

Introduce source-backed distortion. Document the coordinate function, keep it bounded/stable, and remeasure.

### Milestone 4 — Depth / lighting

Introduce depth and lighting behavior while respecting `skipLightingEffects`, then measure the full golden matrix.

### Milestone 5 — Radius blocker resolution

Only after a defensible mapping exists may Custom Glass radius affect blur. Until then: no guessed Gaussian sigma and no hidden empirical constant masquerading as source truth.

## Performance

Profile on actual target hardware before final acceptance, including:

- prewarm behavior;
- first-use latency;
- frame timing with multiple simultaneous glass surfaces;
- GPU cost of distortion and lighting;
- shader lifecycle allocation/churn;
- memory behavior during repeated mount/unmount.

Performance optimization must preserve the measured visual contract.

## Public API stability

`AppleLiquidGlass` remains the public API.

These remain internal:

- strategy selection;
- backend capability;
- typed shader parameters;
- parameter resolver;
- prewarm service;
- FragmentProgram;
- FragmentShader;
- compositor/filter implementation.

Consumers must not pass raw uniforms or renderer calibration values.

## Expected implementation units

```text
lib/app/apple_visual/rendering/
  apple_glass_shader_parameters.dart
  apple_glass_shader_parameter_resolver.dart
  apple_glass_shader_prewarmer.dart

lib/app/apple_visual/rendering/compositor/
  apple_custom_glass_filter.dart
  apple_custom_glass_compositor.dart

test/app/apple_visual/
  apple_glass_shader_parameter_resolver_test.dart
  apple_glass_shader_prewarmer_test.dart
  apple_custom_glass_impeller_test.dart
```

## Non-goals for the first implementation plan

Do not:

- invent radius-to-sigma conversion;
- update Apple source goldens;
- implement every effect in one change;
- share one mutable FragmentShader globally;
- hide unsupported backend behavior;
- bypass Impeller tests;
- expose shader details through the public widget API.

## Acceptance gates

Before this architecture is considered implemented:

- typed source parameter extraction is tested;
- malformed source data fails deterministically;
- prewarm lifecycle is explicit;
- mutable shaders are instance-owned and disposed;
- existing resolver/runtime tests remain green;
- Impeller tests remain green with `--enable-impeller`;
- locked Apple goldens are unchanged;
- identity baseline remains recorded;
- no unauthorized radius-to-sigma mapping exists;
- analyzer is clean for affected scope;
- worktree verification is performed before completion claims.

## Recommended implementation order

1. typed parameter model;
2. parameter resolver RED -> GREEN;
3. prewarm abstraction and test seam;
4. prewarm RED -> GREEN;
5. filter lifecycle refactor;
6. Impeller integration verification;
7. no-visual-change baseline measurement;
8. only then begin the first source-backed visual effect milestone.
