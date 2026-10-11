#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D inputImage;

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
