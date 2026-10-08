import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_blend_mode_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleGlassPlusDarker premultiplied RGBA compositing', () {
    test('composites opaque source over opaque destination component-wise', () {
      const source = AppleGlassPremultipliedRgba(
        red: 0.8,
        green: 0.6,
        blue: 0.4,
        alpha: 1.0,
      );
      const destination = AppleGlassPremultipliedRgba(
        red: 0.7,
        green: 0.5,
        blue: 0.3,
        alpha: 1.0,
      );

      final result = AppleGlassPlusDarkerBlendMath.composite(
        source: source,
        destination: destination,
      );

      expect(result.red, closeTo(0.5, 1e-12));
      expect(result.green, closeTo(0.1, 1e-12));
      expect(result.blue, closeTo(0.0, 1e-12));
      expect(result.alpha, closeTo(1.0, 1e-12));
    });

    test('clamps low-valued premultiplied components to zero', () {
      const source = AppleGlassPremultipliedRgba(
        red: 0.2,
        green: 0.3,
        blue: 0.4,
        alpha: 0.5,
      );
      const destination = AppleGlassPremultipliedRgba(
        red: 0.3,
        green: 0.2,
        blue: 0.1,
        alpha: 0.5,
      );

      final result = AppleGlassPlusDarkerBlendMath.composite(
        source: source,
        destination: destination,
      );

      expect(result.red, 0);
      expect(result.green, 0);
      expect(result.blue, 0);
      expect(result.alpha, 0);
    });

    test('transparent source follows Core Graphics premultiplied equation', () {
      const source = AppleGlassPremultipliedRgba(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0,
      );
      const destination = AppleGlassPremultipliedRgba(
        red: 0.6,
        green: 0.4,
        blue: 0.2,
        alpha: 1.0,
      );

      final result = AppleGlassPlusDarkerBlendMath.composite(
        source: source,
        destination: destination,
      );

      expect(result.red, 0);
      expect(result.green, 0);
      expect(result.blue, 0);
      expect(result.alpha, 0);
    });

    test(
      'transparent destination follows Core Graphics premultiplied equation',
      () {
        const source = AppleGlassPremultipliedRgba(
          red: 0.8,
          green: 0.4,
          blue: 0.2,
          alpha: 1.0,
        );
        const destination = AppleGlassPremultipliedRgba(
          red: 0,
          green: 0,
          blue: 0,
          alpha: 0,
        );

        final result = AppleGlassPlusDarkerBlendMath.composite(
          source: source,
          destination: destination,
        );

        expect(result.red, 0);
        expect(result.green, 0);
        expect(result.blue, 0);
        expect(result.alpha, 0);
      },
    );

    test('composites partially transparent premultiplied pixels', () {
      const source = AppleGlassPremultipliedRgba(
        red: 0.7,
        green: 0.6,
        blue: 0.5,
        alpha: 0.8,
      );
      const destination = AppleGlassPremultipliedRgba(
        red: 0.6,
        green: 0.5,
        blue: 0.4,
        alpha: 0.7,
      );

      final result = AppleGlassPlusDarkerBlendMath.composite(
        source: source,
        destination: destination,
      );

      expect(result.red, closeTo(0.3, 1e-12));
      expect(result.green, closeTo(0.1, 1e-12));
      expect(result.blue, closeTo(0.0, 1e-12));
      expect(result.alpha, closeTo(0.5, 1e-12));
    });

    test('supports asymmetric partial alpha', () {
      const source = AppleGlassPremultipliedRgba(
        red: 0.45,
        green: 0.35,
        blue: 0.25,
        alpha: 0.5,
      );
      const destination = AppleGlassPremultipliedRgba(
        red: 0.75,
        green: 0.70,
        blue: 0.65,
        alpha: 0.9,
      );

      final result = AppleGlassPlusDarkerBlendMath.composite(
        source: source,
        destination: destination,
      );

      expect(result.red, closeTo(0.20, 1e-12));
      expect(result.green, closeTo(0.05, 1e-12));
      expect(result.blue, closeTo(0.0, 1e-12));
      expect(result.alpha, closeTo(0.4, 1e-12));
    });
  });
}
