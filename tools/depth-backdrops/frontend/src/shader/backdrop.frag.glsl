#version 300 es
precision highp float;

in vec2 v_uv;
out vec4 o_color;

uniform sampler2D u_source;
uniform sampler2D u_depth;
uniform bool u_hasSource;
uniform bool u_hasDepth;
uniform vec2 u_canvasSize;
uniform int u_viewMode; // 0=source, 1=depth, 2=styled

uniform float u_gridSize;
uniform float u_gapPx;
uniform float u_inMin;
uniform float u_inMax;
uniform float u_gamma;
uniform float u_contrast;
uniform bool u_invert;

uniform vec3 u_nearColor;
uniform vec3 u_farColor;
uniform vec2 u_valueRange;

uniform float u_marginPx;
uniform vec3 u_marginColor;

void main() {
  vec2 px = v_uv * u_canvasSize;

  if (u_viewMode == 2) {
    bool inFrame =
      px.x < u_marginPx ||
      px.y < u_marginPx ||
      px.x > u_canvasSize.x - u_marginPx ||
      px.y > u_canvasSize.y - u_marginPx;
    if (inFrame) {
      o_color = vec4(u_marginColor, 1.0);
      return;
    }
  }

  if (u_viewMode == 0) {
    o_color = u_hasSource ? texture(u_source, v_uv) : vec4(0.04, 0.04, 0.04, 1.0);
    return;
  }

  vec2 sampleUv = v_uv;
  bool inGap = false;
  if (u_viewMode == 2 && u_gridSize > 0.5) {
    vec2 cellIdx = floor(px / u_gridSize);
    sampleUv = (cellIdx + 0.5) * u_gridSize / u_canvasSize;
    if (u_gapPx > 0.0) {
      vec2 local = px - cellIdx * u_gridSize;
      float half_gap = u_gapPx * 0.5;
      inGap =
        local.x < half_gap ||
        local.y < half_gap ||
        local.x > u_gridSize - half_gap ||
        local.y > u_gridSize - half_gap;
    }
  }

  float d = u_hasDepth ? texture(u_depth, sampleUv).r : 0.5;

  if (u_viewMode == 1) {
    o_color = vec4(vec3(d), 1.0);
    return;
  }

  if (inGap) {
    o_color = vec4(u_farColor, 1.0);
    return;
  }

  float range = max(u_inMax - u_inMin, 1e-4);
  d = clamp((d - u_inMin) / range, 0.0, 1.0);
  if (u_invert) d = 1.0 - d;
  d = pow(d, max(u_gamma, 1e-4));
  d = clamp((d - 0.5) * u_contrast + 0.5, 0.0, 1.0);

  float t = mix(u_valueRange.x, u_valueRange.y, d);
  o_color = vec4(mix(u_farColor, u_nearColor, t), 1.0);
}
