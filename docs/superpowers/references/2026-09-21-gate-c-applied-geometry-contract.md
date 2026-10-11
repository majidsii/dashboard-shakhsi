# Gate C — Applied Geometry Contract

## First locked tuple

`ios27 / light / smallControl / idle`

The generated source recipe now preserves applied usage-layer geometry separately
from shared-style values:

- source material frame: `80 x 48`
- raw usage radius: `3.402823466385289e+38`
- corner smoothing: `0.6`
- corner style: `1`

The raw radius is intentionally preserved. Production code must not replace it
with an invented constant.

## Native Flutter continuous-corner primitive

Gate C uses `dart:ui.RSuperellipse` for this source corner family.

Flutter documents `RSuperellipse` / `ClipRSuperellipse` as closely matching
SwiftUI `RoundedRectangle` with `.continuous` corner style.

The source max-radius sentinel is passed to `RSuperellipse` and then normalized
with `scaleRadii()`. Flutter documents `scaleRadii()` as scaling radii so the
sum on each side does not exceed the width/height.

For the source `80 x 48` frame, this produces a normalized radius of `24`
without hard-coding `24` into the renderer.

## Source export placement

The source recipe's first enabled normal outer shadow is:

- blur radius: `15`
- spread: `0`
- offset X: `0`
- offset Y: `8`

Its source effect expansion is therefore:

- left: `15`
- top: `7`
- right: `15`
- bottom: `23`

Applied to the source material frame:

- width: `80 + 15 + 15 = 110`
- height: `48 + 7 + 23 = 78`

This exactly matches the locked source export canvas.

Therefore, in the locked `110 x 78` source-export fixture, the material body is:

`Rect.fromLTWH(15, 7, 80, 48)`

No centering heuristic and no golden-derived radius is used.

## Failure policy

If a runtime canvas is neither:

- the concrete source frame, nor
- the exact source effect/export frame,

the geometry resolver throws instead of silently scaling or inventing alignment.
