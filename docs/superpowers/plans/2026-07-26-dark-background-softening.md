# Dark Background Softening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Soften the dark animated background so the diagonal sheen does not visually cut through task inputs, while leaving the light theme and foreground glass unchanged.

**Architecture:** Keep the base background gradient sharp. Render the moving blobs and sheen into a dark-only offscreen layer, blur that layer by sigma 20, and scale the dark sheen opacity to 65%. Store both values as explicit design tokens and cover them with a regression test.

**Tech Stack:** Flutter, Dart, CustomPainter, `dart:ui` ImageFilter, flutter_test.

## Global Constraints

- Apply the effect only when `Theme.of(context).brightness == Brightness.dark`.
- Do not change light-theme rendering.
- Do not change task input, glass, layout, data, or interaction code.
- Use `darkAuroraDecorationBlurSigma = 20`.
- Use `darkSheenBandOpacityScale = .65`.

---

### Task 1: Lock the dark background tuning values

**Files:**
- Modify: `app/lib/app/theme/original_design_tokens.dart`
- Modify: `app/test/app/theme/original_design_tokens_test.dart`

**Interfaces:**
- Produces: `OriginalDesignTokens.darkAuroraDecorationBlurSigma`
- Produces: `OriginalDesignTokens.darkSheenBandOpacityScale`

- [ ] Add a failing test expecting sigma `20` and opacity scale `.65`.
- [ ] Run `flutter test test/app/theme/original_design_tokens_test.dart` and confirm the missing-token failure.
- [ ] Add the two constants to `OriginalDesignTokens`.
- [ ] Re-run the test and confirm it passes.

### Task 2: Blur only dark decorative background layers

**Files:**
- Modify: `app/lib/app/widgets/aurora_background.dart`
- Create: `app/tool/verify_dark_background_softening.py`

**Interfaces:**
- Consumes: the two design tokens from Task 1.
- Produces: dark-only blurred blobs and reduced sheen intensity.

- [ ] Pass the current brightness into `_OriginalAuroraPainter`.
- [ ] Keep the neutral base gradient outside the blur layer.
- [ ] Wrap only blobs and sheen in a dark-only `saveLayer` using `ui.ImageFilter.blur`.
- [ ] Multiply sheen opacity by `.65` only in dark mode and by `1` in light mode.
- [ ] Include `dark` in `shouldRepaint`.
- [ ] Run the verifier, analyzer, targeted test, full tests, and Linux app.
