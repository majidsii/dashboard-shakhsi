# Gate C — Impeller Backdrop Filter Contract

## Status

Architecture contract only. No shader has been created by this step.

## Source requirement

Renderer selection is source-backed.

A recipe containing an enabled Apple Custom Glass blur:

- `style.blurs[0].isCustomGlass == 1`
- `style.blurs[0].isEnabled == true`

must select the custom rendering strategy.

The recipe model itself does not contain a manually assigned renderer-policy flag.

## Flutter rendering primitive

The custom Liquid Glass implementation will use Flutter's backdrop-filter pipeline rather than manually capturing the scene into an image.

Target structure:

AppleLiquidGlass
→ AppleGlassRenderStrategyResolver
→ AppleCustomGlassRenderer
→ AppleCustomGlassCompositor
→ clipped BackdropFilter
→ ImageFilter.shader(FragmentShader)

For an ImageFilter shader, Flutter supplies the filter input image to the first sampler and supplies the input dimensions required by the shader contract.

Manual `Scene.toImage`, `RenderRepaintBoundary.toImage`, screenshot capture, or frame-by-frame raster readback is not part of the primary Liquid Glass path.

## Backend capability

`ImageFilter.shader` is an Impeller-only rendering capability.

Runtime support must be checked through:

`ImageFilter.isShaderFilterSupported`

Unsupported backends must not silently pretend that the standard renderer is visually equivalent to the custom Apple Liquid Glass path.

Fallback/deviation behavior must remain explicit and testable.

## Shader lifecycle

Before shader implementation:

1. The fragment program must be an application shader asset.
2. `FragmentProgram.fromAsset` must not run inside paint/build on every frame.
3. Program loading and ownership must have an explicit lifecycle.
4. Reusable shader/program state should be cached where safe.
5. Runtime capability must be determined before constructing an ImageFilter shader path.
6. The filter region must be clipped to the intended glass bounds.
7. Existing locked Apple source goldens remain the visual acceptance authority.

## Shader input contract

The first custom ImageFilter shader prototype will reserve engine-provided input for:

- filter input dimensions
- filter input sampler

Additional uniforms may only be introduced when their mapping to extracted Apple source semantics is documented.

Potential Apple source semantics include:

- saturation
- brightness
- distortion
- depth
- lighting behavior

No arbitrary conversion from Apple Custom Glass `radius` to Flutter Gaussian sigma is authorized.

## First visual target

The first measured prototype remains:

`ios27 / light / smallControl`

Existing baseline:

- pixel mismatch: 61.33%
- differing pixels: 5262

The prototype must be compared against the locked Apple source golden. The golden must not be regenerated from Flutter output.

## Non-goals for this step

- no fragment shader
- no guessed blur radius
- no fake source golden
- no manual screenshot sampling
- no acceptance of visual deviation
