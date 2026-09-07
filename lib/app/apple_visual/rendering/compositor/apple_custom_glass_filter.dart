import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import '../shader/apple_glass_shader_runtime.dart';

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
  final _runtime = AppleGlassShaderRuntime();

  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    if (!ImageFilter.isShaderFilterSupported) {
      return;
    }

    final shader = await _runtime.createShader();

    if (!mounted) {
      return;
    }

    setState(() {
      _shader = shader;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;

    if (shader == null) {
      return widget.child;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.shader(shader),
        child: widget.child,
      ),
    );
  }
}
