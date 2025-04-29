shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always, blend_sub;

uniform vec4 ring_color : source_color = vec4(1.0, 0.6, 0.3, 1.0);
uniform float center_width : hint_range(0.0, 1.0) = 0.2;
uniform float edge_width : hint_range(0.0, 1.0) = 0.1;

void fragment() {
  // нормализованный вектор к камере
  vec3 view_dir = normalize(VIEW);

  // угол между нормалью и направлением взгляда
  float angle = dot(NORMAL, view_dir);

  // чем ближе к краю (перпендикулярно взгляду), тем меньше значение
  float rim = 1.0 - abs(angle);

  // создаём "кольцо" с мягкими краями
  float ring = smoothstep(center_width, center_width + edge_width, rim);

  ALBEDO = ring_color.rgb;
  ALPHA = ring * ring_color.a;
}
