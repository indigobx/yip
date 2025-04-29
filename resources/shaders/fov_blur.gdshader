shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform mat4 camera_global_transform;
uniform vec3 focus_point;
uniform vec3 vision_point;

uniform float sharp_fov_deg = 90.0;
uniform float peripheral_fov_deg = 110.0;

void fragment() {
  vec3 world_view_dir = normalize(focus_point - vision_point);

  // Преобразуем вектор в координаты камеры
  mat3 cam_basis = mat3(camera_global_transform);
  vec3 view_cam = transpose(cam_basis) * world_view_dir;

  // Убираем глубину — оставляем только направление на экране (X и Y)
  vec2 view_cam_dir_2d = normalize(view_cam.xy);

  // Центрируем пиксель по экрану (Y инвертирован, чтобы вверх был вверх)
  vec2 screen_uv = SCREEN_UV;
  vec2 centered_uv = (screen_uv - vec2(0.5)) * vec2(1.0, -1.0);
  vec2 pixel_dir_2d = normalize(centered_uv);

  // Вычисляем угол между направлением взгляда и пикселем на экране
  float angle_deg = degrees(acos(dot(view_cam_dir_2d, pixel_dir_2d)));

  // Плавное размытие по углу
  float t = smoothstep(sharp_fov_deg, peripheral_fov_deg, angle_deg);

  float blur_strength = mix(0.0, 2.5, t);
  vec4 blurred = textureLod(SCREEN_TEXTURE, screen_uv, blur_strength);

  // Оттенки серого + лёгкое затемнение
  vec3 grayscale = vec3(dot(blurred.rgb, vec3(0.299, 0.587, 0.114)));
  grayscale *= 0.8; // затемнение на 20%
  vec3 final_rgb = mix(blurred.rgb, grayscale, t);

  COLOR = vec4(final_rgb, 1.0);

}