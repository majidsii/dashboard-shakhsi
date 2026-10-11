import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import '../shader/apple_glass_shader_runtime.dart';
import '../shader/apple_glass_shader_uniform_mapper.dart';
import '../shader/apple_glass_shader_uniform_resolver.dart';

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
  final _uniformResolver = const AppleGlassShaderUniformResolver();
  final _uniformMapper = const AppleGlassShaderUniformMapper();

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

    final uniforms = _uniformResolver.resolve(widget.recipe);

    _uniformMapper.apply(shader, uniforms);

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

    return BackdropFilter(
      filter: ImageFilter.shader(shader),
      child: widget.child,
    );
  }
}
