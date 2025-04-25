shader_type spatial;
render_mode unshaded, blend_mix, cull_back;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NOISE_TEXTURE : source_color;

uniform float distortion_strength = 0.02;
uniform float noise_scale = 4.0;
uniform float time_scale = 1.0;

void fragment() {
  float edge_mask = smoothstep(0.0, 0.15, UV.x) * smoothstep(0.0, 0.15, 1.0 - UV.x)
                * smoothstep(0.0, 0.15, UV.y) * smoothstep(0.0, 0.15, 1.0 - UV.y);
  // Генерация смещения через noise
  vec2 noise_uv = UV * noise_scale + vec2(TIME * time_scale, 0.0);
  vec2 noise_sample = texture(NOISE_TEXTURE, noise_uv).rg;

  // Смещение UV в диапазоне [-0.5 .. 0.5], умноженное на силу
  vec2 distortion = (noise_sample - 0.5) * distortion_strength;

  // Получаем цвет с экрана со смещением
  vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + distortion);

  // Финальный цвет и прозрачность
  ALBEDO = screen_color.rgb;
  ALPHA *= edge_mask;
}