#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D inputImage;

uniform float uSaturation;
uniform float uBrightness;
uniform float uDistortion;
uniform float uDepth;
uniform float uChromaticAberration;
uniform float uGlassRadius;
uniform float uLighting;

out vec4 fragColor;

void main() {

    vec2 uv =
        FlutterFragCoord().xy /
        uSize;

    vec4 color =
        texture(
            inputImage,
            uv
        );

    fragColor = color;
}
