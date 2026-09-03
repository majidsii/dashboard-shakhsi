import 'dart:convert';
import 'dart:io';

import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_theme.dart';
import 'package:dashboard_shakhsi/app/apple_visual/widgets/apple_liquid_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleLiquidGlass source-consumption contract', () {
    testWidgets('resolves the exact source-backed tuple into diagnostics', (
      tester,
    ) async {
      final theme = _resolvedTheme(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
      );

      final widget = AppleLiquidGlass(
        theme: theme,
        role: AppleGlassRole.mediumSurface,
        state: AppleControlState.idle,
        child: const SizedBox(
          key: ValueKey<String>('liquid-glass-child'),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      );

      final mounted = tester.widget<AppleLiquidGlass>(
        find.byType(AppleLiquidGlass),
      );

      final actual = mounted.debugRenderDiagnostics.recipe;

      final expected = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        role: AppleGlassRole.mediumSurface,
        state: AppleControlState.idle,
      );

      expect(actual.family, expected.family);
      expect(actual.brightness, expected.brightness);
      expect(actual.role, expected.role);
      expect(actual.state, expected.state);
      expect(actual.sourceIds, expected.sourceIds);
      expect(actual.sourceNames, expected.sourceNames);
      expect(actual.sourceValues, expected.sourceValues);
      expect(actual.roleMappingEvidence, expected.roleMappingEvidence);

      expect(
        find.byKey(const ValueKey<String>('liquid-glass-child')),
        findsOneWidget,
      );
    });

    test('constructor defaults state to idle and requires no visual overrides', () {
      final theme = _resolvedTheme(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
      );

      final widget = AppleLiquidGlass(
        theme: theme,
        role: AppleGlassRole.smallControl,
        child: const SizedBox.shrink(),
      );

      expect(widget.theme, same(theme));
      expect(widget.role, AppleGlassRole.smallControl);
      expect(widget.state, AppleControlState.idle);
    });

    test('public constructor exposes no raw visual override parameters', () {
      final source = File(
        'lib/app/apple_visual/widgets/apple_liquid_glass.dart',
      ).readAsStringSync();

      final constructor = RegExp(
        r'const AppleLiquidGlass\(\{[\s\S]*?\}\);',
      ).firstMatch(source);

      expect(constructor, isNotNull);

      final contract = constructor!.group(0)!;

      for (final forbidden in <String>[
        'blurSigma',
        'opacity',
        'radius',
        'borderColor',
      ]) {
        expect(contract, isNot(contains(forbidden)));
      }
    });
  });

  group('AppleLiquidGlass source goldens', () {
    const cases = <_GoldenCase>[
      _GoldenCase(
        path: 'ios27/light/small-control.png',
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        name: 'ios27 light smallControl matches locked Apple source',
      ),
      _GoldenCase(
        path: 'ios27/dark/small-control.png',
        family: AppleVisualFamily.ios27,
        brightness: Brightness.dark,
        role: AppleGlassRole.smallControl,
        name: 'ios27 dark smallControl matches locked Apple source',
      ),
      _GoldenCase(
        path: 'ios27/light/medium-surface.png',
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.mediumSurface,
        name: 'ios27 light mediumSurface matches locked Apple source',
      ),
      _GoldenCase(
        path: 'ios27/dark/medium-surface.png',
        family: AppleVisualFamily.ios27,
        brightness: Brightness.dark,
        role: AppleGlassRole.mediumSurface,
        name: 'ios27 dark mediumSurface matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/light/small-control.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        name: 'macos27 light smallControl matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/dark/small-control.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        role: AppleGlassRole.smallControl,
        name: 'macos27 dark smallControl matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/light/medium-surface.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
        role: AppleGlassRole.mediumSurface,
        name: 'macos27 light mediumSurface matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/dark/medium-surface.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        role: AppleGlassRole.mediumSurface,
        name: 'macos27 dark mediumSurface matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/light/over-glass-control.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
        role: AppleGlassRole.overGlassControl,
        name: 'macos27 light overGlassControl matches locked Apple source',
      ),
      _GoldenCase(
        path: 'macos27/dark/over-glass-control.png',
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
        role: AppleGlassRole.overGlassControl,
        name: 'macos27 dark overGlassControl matches locked Apple source',
      ),
    ];

    for (final goldenCase in cases) {
      testWidgets(goldenCase.name, (tester) async {
        final fixture = _manifestFixture(goldenCase.path);

        expect(fixture['state'], 'idle');

        final logicalSize = fixture['logicalSize'] as List<dynamic>;
        final width = (logicalSize[0] as num).toDouble();
        final height = (logicalSize[1] as num).toDouble();
        final dpr = (fixture['devicePixelRatio'] as num).toDouble();

        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = Size(
          width * dpr,
          height * dpr,
        );

        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final theme = _resolvedTheme(
          family: goldenCase.family,
          brightness: goldenCase.brightness,
        );

        final boundaryKey = ValueKey<String>(
          'golden-${goldenCase.path}',
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: width,
                height: height,
                child: AppleLiquidGlass(
                  theme: theme,
                  role: goldenCase.role,
                  state: AppleControlState.idle,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            '../../goldens/apple/${goldenCase.path}',
          ),
        );
      });
    }
  });
}

final class _GoldenCase {
  const _GoldenCase({
    required this.path,
    required this.family,
    required this.brightness,
    required this.role,
    required this.name,
  });

  final String path;
  final AppleVisualFamily family;
  final Brightness brightness;
  final AppleGlassRole role;
  final String name;
}

Map<String, dynamic> _manifestFixture(String path) {
  final manifest = jsonDecode(
    File('test/goldens/apple/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final fixtures = manifest['fixtures'] as List<dynamic>;

  return fixtures
      .cast<Map<String, dynamic>>()
      .singleWhere((fixture) => fixture['path'] == path);
}

AppleVisualThemeData _resolvedTheme({
  required AppleVisualFamily family,
  required Brightness brightness,
}) {
  return AppleVisualThemeData(
    family: family,
    brightness: brightness,
    colors: AppleSourceTokenMapper.colors(
      family: family,
      brightness: brightness,
    ),
    typography: AppleSourceTokenMapper.typography(family: family),
    metrics: AppleSourceTokenMapper.metrics(family: family),
    materials: AppleSourceTokenMapper.materials(family: family),
    motion: AppleSourceTokenMapper.motion(family: family),
  );
}
