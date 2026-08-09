# Visual Foundation 2.A — Exact Typography and Symbol Fidelity Blocker

Date: 2026-08-09
Status: **BLOCKING — USER DECISION / EXTERNAL RIGHTS OR ASSETS REQUIRED**
Boundary: **Gate A — Reproducible Source Extraction Before Visual Code**

## Why this document exists

Gate A source extraction is green, but the frozen fidelity contract does not
allow an unresolved source dependency to be silently replaced by a visually
similar fallback.

Two exactness dependencies remain unresolved for Android, Windows and Linux:

1. Apple system typography for Persian and Latin text;
2. Apple/SF-symbol-compatible icon rendering.

This blocker does not weaken the frozen fidelity contract.

## Source evidence — typography

The supplied iOS 27 and macOS 27 Sketch archives contain font references and
PostScript/font descriptor names such as SF Pro and related San Francisco
families.

The supplied Sketch archives do **not** embed `.ttf`, `.otf`, `.woff`, or
`.woff2` font binaries.

Apple's current developer typography resources identify SF Pro as the system
font for Apple platforms and SF Arabic as the Arabic-script extension. Apple's
WWDC material explicitly states that SF Arabic supports Persian.

Official Apple sources:

- https://developer.apple.com/fonts/
- https://developer.apple.com/videos/play/wwdc2022/110381/

The Apple San Francisco font license displayed by Apple restricts the font to
the licensed Apple-platform/mock-up uses described by that license and states
that the font may not be embedded in software products or used for non-Apple
operating-system UI mock-ups unless Apple expressly permits otherwise in
writing.

Therefore the project must not bundle an Apple San Francisco font into the
Android, Windows, or Linux application and call that path an approved exact
implementation without an independently valid permission/license.

## Source evidence — symbols/icons

The supplied Sketch references contain many symbol/icon layers as text glyphs
using private-use Unicode characters with SF Pro font descriptors and feature
settings. These are not equivalent to independent vector paths embedded for
general cross-platform runtime use.

The archives also contain ordinary shape/vector/bitmap content for some
components, but the source does not provide an independent vector replacement
for every runtime icon the current dashboard needs.

Apple documents SF Symbols as a symbol library that integrates with the San
Francisco system font and publishes additional usage restrictions for symbols.

Official Apple sources:

- https://developer.apple.com/sf-symbols/
- https://developer.apple.com/design/human-interface-guidelines/sf-symbols

Therefore Material `Icons.*`, Cupertino icons, or hand-drawn Apple-like icons
must not be silently treated as exact replacements under the frozen contract.

## Consequence for the frozen contract

Gate A extraction itself is green:

- exact source hashes are verified;
- deterministic generated reference JSON exists;
- source page/style/swatches/text-style data is extracted;
- Liquid Glass source metadata is present;
- the manifest Flutter test is green.

However Gate A is **not complete** because exact cross-platform typography and
symbol runtime assets are unresolved.

## Accepted ways to unblock exact fidelity

One of the following must become true before Gate B can be declared fully
unblocked:

1. the project obtains explicit rights/permission and legally usable runtime
   assets that allow the required Apple typography/symbol assets on the target
   non-Apple platforms; or
2. the user explicitly changes the frozen fidelity contract and approves a
   named, documented deviation for typography and/or symbols.

Until one of those events occurs:

- do not use Vazirmatn as an "exact" Apple typography substitute;
- do not use Material Icons as "exact" Apple symbols;
- do not create a visually-similar fallback and hide the difference;
- do not mark Visual Foundation 2.A complete;
- do not mark Gate A complete;
- do not start Gate B as though these dependencies were resolved.

## Current implementation state

Production UI code remains unchanged.

The committed Gate A extraction boundary is evidence/tooling only and does not
represent acceptance of any visual deviation.
