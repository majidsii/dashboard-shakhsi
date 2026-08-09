# Apple UI Kit Source Manifest — Visual Foundation 2.A

Date: 2026-08-09
Status: **SOURCE-LOCKED**
Purpose: identify the exact external Apple UI reference files that define the visual target for `dashboard-shakhsi-v2-integration`.

## Source precedence

For Visual Foundation 2.A, the supplied Apple Sketch references are the visual source of truth.

If any of the following conflict:

1. supplied Apple Sketch reference;
2. existing application styling;
3. an earlier mockup;
4. framework defaults;
5. Material, Fluent, Windows/Linux native conventions;
6. developer/designer preference;

the supplied Apple reference wins unless the user explicitly changes the frozen fidelity contract.

## Exact supplied files

### macOS

File name:

`Apple macOS 27 UI Kit(1).sketch`

SHA-256:

`8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`

Verified Sketch structure:

- 37 page JSON files;
- 285 shared layer styles;
- 67 shared text styles;
- 110 shared swatches.

Human-readable page/component families include:

- Library Preview
- Colors
- Materials
- Alerts
- Buttons
- Color Wells
- Combo Boxes
- Dialogs
- Disclosure Controls
- Forms
- Group Boxes
- Image Wells
- Menu Bar and Dock
- Menus
- Notifications
- Pointers
- Pop-up and Pull-down Buttons
- Popovers
- Progress Indicators
- Scrollbars
- Search Fields
- Segmented Controls
- Sidebars
- Sliders
- Steppers
- Text Fields
- Titlebars and Toolbars
- Toggles — Checkboxes
- Toggles — Radio Buttons
- Toggles — Switches
- Tooltips
- Windows
- Change Log
- Kit

### iOS

File name:

`Apple iOS 27 UI Kit.sketch`

SHA-256:

`5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`

Verified Sketch structure:

- 34 page JSON files;
- 42 shared layer styles;
- 105 shared text styles;
- 107 shared swatches.

Human-readable page/component families include:

- Library Preview
- Colors
- Materials
- Text Styles and Dynamic Type
- System
- Activity Views
- Action Sheets
- Alerts
- Buttons
- Color Wells and Pickers
- Date and Time Pickers
- Empty States
- FaceID
- Keyboards
- Lists
- Menus
- Page Controls
- Popovers
- Progress Indicators
- Segmented Controls
- Sheets
- Sidebars
- Sliders
- Steppers
- Tab Bars
- Text Fields
- Toggles
- Toolbars
- Change Log
- Kit

### macOS companion asset bundle

File name:

`apple-macos-27-ui-kit_assets_2026-06-23_v12(1).zip`

SHA-256:

`4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31`

Verified bundle:

- 23 files total;
- `Library Preview.png`;
- pointer SVG references for default, grabbing/open/pointing hand, move, text cursor,
  zoom, directional resizing, cross and beachball states.

## Availability rule

The binary Sketch/asset files are external visual references and are not silently replaced by screenshots, memory, generic Apple documentation, framework samples or hand-tuned guesses.

A future assistant/session that cannot access the exact source files may:

- read this manifest;
- read the frozen contract and canonical design;
- continue documentation/governance work that does not require new visual measurements.

It must **not** invent missing visual values.

Before extracting new component values or claiming pixel/source fidelity, the exact source files above must be available and their SHA-256 values must match this manifest, or the user must explicitly approve a replacement source revision.

## Revision rule

A newer Apple kit does not automatically replace these files.

Changing any source file or source hash is a design-contract change and requires:

1. explicit user approval;
2. manifest update;
3. impact review against existing extracted tokens/components;
4. Roadmap/spec update before implementation continues.
