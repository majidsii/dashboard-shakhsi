# Gate C — Blend and Corner Semantics Reference

## Status

Source semantics are documented here before they are used for rendering.

No unsupported Sketch blend mode may silently fall back to `BlendMode.srcOver`.
No generic `ClipRRect` may be introduced as a substitute for unresolved Sketch corner
semantics.

## Sketch blend-mode identifiers

The extracted source recipes use Sketch `GraphicsContextSettings.blendMode` integer
identifiers.

The Sketch file-format enum order is:

| Raw | Sketch semantic |
|---:|---|
| 0 | Normal |
| 1 | Darken |
| 2 | Multiply |
| 3 | Color Burn |
| 4 | Lighten |
| 5 | Screen |
| 6 | Color Dodge |
| 7 | Overlay |
| 8 | Soft Light |
| 9 | Hard Light |
| 10 | Difference |
| 11 | Exclusion |
| 12 | Hue |
| 13 | Saturation |
| 14 | Color |
| 15 | Luminosity |
| 16 | Plus Darker |
| 17 | Plus Lighter |

References:

- Sketch Developer API — `Style.BlendingMode`
  https://developer.sketch.com/reference/api/
- Sketch file-format TypeScript enum lineage
  https://github.com/sketch-hq/sketch-file-format-ts

## Flutter mapping

The standard modes 0–15 map to their same-named Flutter `dart:ui.BlendMode`
counterparts, with Sketch `Normal` represented by `BlendMode.srcOver`.

Sketch `Plus Lighter` maps to Flutter `BlendMode.plus` because both use additive
component compositing with clamping.

Sketch `Plus Darker` has no direct Flutter `BlendMode` equivalent and therefore remains a
custom-compositing requirement.

References:

- Flutter `BlendMode`
  https://api.flutter.dev/flutter/dart-ui/BlendMode.html
- Apple Core Graphics `CGBlendMode`
  https://developer.apple.com/documentation/coregraphics/cgblendmode

Apple documents the equations:

- Plus Lighter: `R = MIN(1, S + D)`
- Plus Darker: `R = MAX(0, 1 - ((1 - D) + (1 - S)))`

The latter simplifies per premultiplied component to:

`R = MAX(0, S + D - 1)`

The renderer must preserve Apple/Core Graphics alpha semantics when the custom path is
implemented; channel math alone is not sufficient proof of complete compositing
equivalence.

## First target requirements

`ios27/light/smallControl` contains blend identifiers:

- fills: 0, 15, 17
- shadows: 0, 16, 17

Therefore the first target cannot be implemented purely with Flutter-native blend modes:
at least the `Plus Darker` shadow layers require custom compositing.

## Corner semantics

The first target contains:

- `style.corners.prefersConcentric = false`
- `style.corners.smoothing = 0.6`
- `style.corners.style = 1`
- no explicit `style.corners.radii[0]` in the extracted target tuple

Current Sketch API documentation states that corner smoothing is meaningful for
`Style.CornerStyle.Smooth`, and that 0.6 is the default smoothing amount for smooth
corners.

However, this evidence does **not** yet establish a defensible mapping from the raw
serialized integer `style.corners.style = 1` in this extracted Apple source tuple to a
Flutter geometry primitive, nor does it establish the missing effective radius.

Therefore:

- do not infer a circular radius;
- do not map this target to `ClipRRect`;
- do not invent a radius from the glass blur radius;
- keep exact geometry clipping blocked until effective shape/radius evidence is recovered.

Reference:

- Sketch Developer API — Corners
  https://developer.sketch.com/reference/api/
