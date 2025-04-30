shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform mat4 camera_global_transform;
uniform vec3 focus_point;
uniform vec3 vision_point;

uniform float sharp_fov_deg = 30.0;
uniform float peripheral_fov_deg = 90.0;

uniform float vision_focus_radius_min = 0.1;
uniform float vision_focus_radius_max = 0.3;

uniform vec3 sharp_sensitivity = vec3(1.0);
uniform vec3 peripheral_sensitivity = vec3(0.2, 0.9, 0.1);

uniform bool affect_sharp_area = false;

uniform vec3 sharp_color = vec3(0.25);
uniform float sharp_gamma = 1.0;
uniform float sharp_contrast = 0.5;

uniform vec3 perpipheral_color = vec3(0.25);
uniform float peripheral_gamma = 0.8;
uniform float peripheral_contrast = 0.5;

void fragment() {
  // Вектор взгляда
  vec3 world_view_dir = normalize(focus_point - vision_point);
  mat3 cam_basis = mat3(camera_global_transform);
  vec3 view_cam = transpose(cam_basis) * world_view_dir;
  vec2 view_cam_dir_2d = normalize(view_cam.xy);

  vec2 screen_uv = SCREEN_UV;
  vec2 centered_uv = (screen_uv - vec2(0.5)) * vec2(1.0, -1.0);
  vec2 pixel_dir_2d = normalize(centered_uv);

  // Угол между направлением взгляда и пикселем
  float angle_deg = degrees(acos(dot(view_cam_dir_2d, pixel_dir_2d)));
  float angle_t = smoothstep(sharp_fov_deg, peripheral_fov_deg, angle_deg);

  // Чёткость вблизи vision_point
  float dist_to_center = length(centered_uv);
  float radius_t = smoothstep(vision_focus_radius_min, vision_focus_radius_max, dist_to_center);

  // Общий уровень размытия
  float t = angle_t * radius_t;

  // Чтение размытого экрана
  float blur_strength = mix(0.0, 3.5, t);
  vec4 blurred = textureLod(SCREEN_TEXTURE, screen_uv, blur_strength);

  // Настройка sharp зоны
  vec3 sharp_gray = pow(vec3(dot(blurred.rgb, sharp_sensitivity)), vec3(sharp_gamma));
  sharp_gray = mix(sharp_color, sharp_gray, sharp_contrast);

  // Настройка peripheral зоны
  vec3 peripheral_gray = pow(vec3(dot(blurred.rgb, peripheral_sensitivity)), vec3(peripheral_gamma));
  peripheral_gray = mix(perpipheral_color, peripheral_gray, peripheral_contrast);


  // Теперь выбираем:
  vec3 target_color;
  if (affect_sharp_area) {
    // всегда применять эффект с плавным переходом
    target_color = mix(sharp_gray, peripheral_gray, t);
  } else {
    // оставить sharp-область нетронутой
    target_color = mix(blurred.rgb, peripheral_gray, t);
  }

  COLOR = vec4(target_color, 1.0);
}
