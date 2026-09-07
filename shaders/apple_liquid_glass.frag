#version 460 core

#include <flutter/runtime_effect.glsl>

uniform sampler2D inputImage;

uniform float saturation;
uniform float brightness;
uniform float distortion;
uniform float depth;
uniform float chromaticAberration;
uniform float customGlassRadius;


out vec4 fragColor;


void main() {

    vec2 uv = FlutterFragCoord().xy;

    vec2 size = vec2(
        textureSize(
            inputImage,
            0
        )
    );

    uv = uv / size;


    vec4 color =
        texture(
            inputImage,
            uv
        );


    color.rgb *= brightness;


    color.rgb =
        mix(
            vec3(
                dot(
                    color.rgb,
                    vec3(
                        0.2126,
                        0.7152,
                        0.0722
                    )
                )
            ),
            color.rgb,
            saturation
        );


    color.rgb +=
        distortion *
        0.001;


    color.rgb +=
        depth *
        0.002;


    color.rgb +=
        chromaticAberration *
        0.001;


    fragColor = color;
}
