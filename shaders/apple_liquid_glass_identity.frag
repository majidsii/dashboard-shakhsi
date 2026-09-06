#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture_input;

out vec4 frag_color;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  frag_color = texture(u_texture_input, uv);
}
