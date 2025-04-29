shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_always, shadows_disabled;

uniform vec4 center_color : source_color = vec4(5.0, 0.0, 0.0, 1.0); // HDR яркий центр
uniform vec4 mid_color : source_color = vec4(2.0, 0.0, 0.0, 1.0);    // HDR середина
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);   // Полупрозрачные края

uniform bool cubic_interpolation = false; // true = кубическая интерполяция

void fragment() {
  // UV координаты: ожидаем, что X идёт слева направо
  float u = abs(UV.x - 0.5) * 2.0; // 0.0 в центре, 1.0 на краях

  // Выбираем интерполяцию
  float t = cubic_interpolation ? (u * u * (3.0 - 2.0 * u)) : u; // cubic или linear

  // Сначала от CenterColor к MidColor, потом к EdgeColor
  vec4 color = mix(center_color, mid_color, t);
  color = mix(color, edge_color, t);

  ALBEDO = color.rgb;
  ALPHA = color.a;
}
