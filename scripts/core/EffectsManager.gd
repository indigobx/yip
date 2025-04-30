extends Node3D

var max_decals = 300
@onready var cursor_tracker = PlayerData.vega.get_node("TrackCursor")
@onready var exposure_camera = $ExposureViewport/ExposureMeter
@onready var exposure_viewport = $ExposureViewport

func _ready() -> void:
  exposure_viewport.world_3d = get_world_3d()


func _process(delta: float) -> void:
  _move_exposure_meter()
  _meter_exposure()


func _move_exposure_meter() -> void:
  var target_transform = cursor_tracker.global_transform

  # Извлекаем текущий поворот
  var rotation_euler = target_transform.basis.get_euler()

  # Ограничиваем наклон по X (вверх/вниз)
  var clamped_x = clamp(rotation_euler.x, deg_to_rad(-45), deg_to_rad(10))

  # Собираем финальный поворот: ограниченный X, свободный Y, нулевой крен (Z)
  var final_rotation = Vector3(clamped_x, rotation_euler.y, 0.0)
  var new_basis = Basis.from_euler(final_rotation)

  # Применяем ориентацию с сохранением позиции
  target_transform.basis = new_basis
  exposure_camera.global_transform = target_transform




func _meter_exposure() -> void:
  var texture = exposure_viewport.get_texture()
  if not texture:
    return

  var img = texture.get_image()
  if not img:
    return

  var size = img.get_size()
  var luminance_sum := 0.0
  var sample_count := 0

  for y in size.y:
    for x in size.x:
      var color = img.get_pixel(x, y)
      var luminance = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
      luminance_sum += luminance
      sample_count += 1

  if sample_count == 0:
    return

  var average_luminance = luminance_sum / sample_count
  var ev100 = log(average_luminance * 100.0 / 12.5) / log(2)

  var target_luminance = 1.0
  var exposure = log(target_luminance / (average_luminance + 0.001)) / log(2)
  PlayerData.ev = clamp(exposure, -12.0, 12.0)
  #print("EV100: %.2f   EXP: %.2f" % [ev100, PlayerData.ev])


func add_decal(decal, hit, scale:float=1.0) -> void:
  var decal_instance = decal.instantiate()
  $Decals.add_child(decal_instance)
  decal_instance.scale = Vector3(scale, scale, scale)
  decal_instance.global_position = hit.position
  decal_instance.rotation = hit.position + hit.normal
  cleanup_decals()


func cleanup_decals() -> void:
  var decals_count = $Decals.get_child_count()
  if decals_count > max_decals:
    var first_decal = $Decals.get_child(0)
    first_decal.queue_free()


func set_glow(glow_params:Dictionary) -> void:
  if "intensity" in glow_params:
    $WorldEnvironment.environment.glow_intensity = glow_params.intensity
  if "strength" in glow_params:
    $WorldEnvironment.environment.glow_strength = glow_params.strength
  if "bloom" in glow_params:
    $WorldEnvironment.environment.glow_bloom = glow_params.bloom
  if "blend_mode" in glow_params:
    $WorldEnvironment.environment.glow_blend_mode = glow_params.blend_mode
  else:
    $WorldEnvironment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
