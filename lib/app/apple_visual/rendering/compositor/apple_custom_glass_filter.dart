import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import '../shader/apple_liquid_glass_shader_repository.dart';
import '../shader/apple_liquid_glass_shader_repository.dart';

final class AppleCustomGlassFilter extends StatefulWidget {
  const AppleCustomGlassFilter({
    required this.recipe,
    required this.child,
    super.key,
  });

  final AppleLiquidGlassRecipe recipe;
  final Widget child;

  @override
  State<AppleCustomGlassFilter> createState() => _AppleCustomGlassFilterState();
}

final class _AppleCustomGlassFilterState extends State<AppleCustomGlassFilter> {
  ui.FragmentShader? _shader;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      if (mounted) {
        setState(() {
          _loadError = UnsupportedError(
            'Apple Custom Glass requires '
            'ImageFilter.shader support from Impeller.',
          );
        });
      }
      return;
    }

    try {
      final program = await AppleLiquidGlassShaderRepository.instance
          .loadProgram();

      if (!mounted) {
        return;
      }

      final shader = program.fragmentShader();

      setState(() {
        _shader = shader;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = error;
      });
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _loadError;

    if (error != null) {
      throw FlutterError(
        'Failed to initialize Apple Custom Glass shader: $error',
      );
    }

    final shader = _shader;

    if (shader == null) {
      return widget.child;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.shader(shader),
        child: widget.child,
      ),
    );
  }
}
