extends CanvasLayer

enum VisionMode { NORMAL, NVG2, NVG3 }
@export var vision_offset := Vector3.ZERO
var sharp_fov_deg := 30.0
var peripheral_fov_deg := 90.0
var vision_focus_radius_min := 0.1
var vision_focus_radius_max := 0.3
var sharp_sensitivity := Vector3(1.0, 1.0, 1.0)
var peripheral_sensitivity := Vector3(0.2, 0.9, 0.1)
var affect_sharp_area := false
var sharp_color := Vector3(0.25, 0.25, 0.25)
var sharp_gamma := 1.0
var sharp_contrast := 0.5
var perpipheral_color := Vector3(0.25, 0.25, 0.25)
var peripheral_gamma := 0.8
var peripheral_contrast := 0.5
var vision_mode := VisionMode.NORMAL

@onready var camera = get_tree().root.get_node("Main/Managers/CameraController")
@onready var effects = get_tree().root.get_node("Main/Managers/EffectsManager")

func _ready() -> void:
  InputHandler.connect("night_vision_pressed", Callable(self, "_on_night_vision_pressed"))
  _set_normal_vision()


func _process(delta: float) -> void:
  var shader_material = $FovRect.material as ShaderMaterial
  var vision_screen_uv = camera.camera.unproject_position(GameState.vision_point)
  # unproject_position вернёт (x, y) в мировых координатах камеры, надо пересчитать в UV
  var viewport_size = get_viewport().size
  vision_screen_uv = Vector2(vision_screen_uv.x / viewport_size.x, vision_screen_uv.y / viewport_size.y)

  shader_material.set_shader_parameter("vision_screen_uv", vision_screen_uv)
  shader_material.set_shader_parameter("camera_global_transform", camera.camera.global_transform)
  shader_material.set_shader_parameter("focus_point", GameState.focus_point)
  shader_material.set_shader_parameter("vision_point", GameState.vision_point + vision_offset)
  shader_material.set_shader_parameter("sharp_fov_deg", sharp_fov_deg)
  shader_material.set_shader_parameter("peripheral_fov_deg", peripheral_fov_deg)
  shader_material.set_shader_parameter("vision_focus_radius_min", vision_focus_radius_min)
  shader_material.set_shader_parameter("vision_focus_radius_max", vision_focus_radius_max)
  shader_material.set_shader_parameter("sharp_sensitivity", sharp_sensitivity)
  shader_material.set_shader_parameter("peripheral_sensitivity", peripheral_sensitivity)
  shader_material.set_shader_parameter("affect_sharp_area", affect_sharp_area)
  shader_material.set_shader_parameter("sharp_color", sharp_color)
  shader_material.set_shader_parameter("sharp_gamma", sharp_gamma)
  shader_material.set_shader_parameter("sharp_contrast", sharp_contrast)
  shader_material.set_shader_parameter("perpipheral_color", perpipheral_color)
  shader_material.set_shader_parameter("peripheral_gamma", peripheral_gamma)
  shader_material.set_shader_parameter("peripheral_contrast", peripheral_contrast)
  
  #var exposure = PlayerData.ev
  match vision_mode:
    VisionMode.NORMAL:
      camera.set_exposure(1.0)
    VisionMode.NVG2:
      var exposure = 5.0 * randf_range(1.8, 2.2)
      camera.set_exposure(exposure)
    VisionMode.NVG3:
      var t := Time.get_ticks_msec() / 1000.0
      var exposure = 2.0 + sin(t * 4.0) * 0.25
      camera.set_exposure(exposure)

  
func _set_nvg_2() -> void:
  vision_mode = VisionMode.NVG2
  sharp_fov_deg = 40.0
  peripheral_fov_deg = 50.0
  vision_focus_radius_min = 0.05
  vision_focus_radius_max = 0.15
  sharp_sensitivity = Vector3(0.1, 1.0, 0.1)
  peripheral_sensitivity = Vector3(0.1, 0.1, 0.1)
  affect_sharp_area = true
  sharp_color = Vector3(0.4, 0.95, 0.2)
  sharp_gamma = 1.3
  sharp_contrast = 0.8
  perpipheral_color = Vector3(0.01, 0.05, 0.01)
  peripheral_gamma = 0.5
  peripheral_contrast = 0.1
  camera.set_auto_exposure(true, -8.0, -4.0, 0.5, 0.9)
  #camera.set_auto_exposure(false)
  effects.set_glow({
    'strength': 0.5,
    'blend_mode': Environment.GLOW_BLEND_MODE_ADDITIVE
  })
  if PlayerData.vega:
    PlayerData.vega.flashlight_mode("ir_flashlight")

func _set_nvg_3() -> void:
  vision_mode = VisionMode.NVG3
  sharp_fov_deg = 25.0
  peripheral_fov_deg = 45.0
  vision_focus_radius_min = 0.2
  vision_focus_radius_max = 0.35
  sharp_sensitivity = Vector3(0.25, 0.9, 0.8)
  peripheral_sensitivity = Vector3(0.1, 0.1, 0.1)
  affect_sharp_area = true
  sharp_color = Vector3(0.7, 0.85, 1.0)
  sharp_gamma = 1.7
  sharp_contrast = 0.5
  perpipheral_color = Vector3(0.01, 0.05, 0.15)
  peripheral_gamma = 0.9
  peripheral_contrast = 0.5
  camera.set_auto_exposure(true, -8.0, 2.0, 16.0, 0.9)
  #camera.set_auto_exposure(false)
  effects.set_glow({
    'strength': 1.0
  })
  if PlayerData.vega:
    PlayerData.vega.flashlight_mode("ir_omni")
    
func _set_normal_vision() -> void:
  vision_mode = VisionMode.NORMAL
  sharp_fov_deg = 60.0
  peripheral_fov_deg = 120.0
  vision_focus_radius_min = 0.3
  vision_focus_radius_max = 0.4
  sharp_sensitivity = Vector3(1.0, 1.0, 1.0)
  peripheral_sensitivity = Vector3(0.85, 0.55, 0.9)
  affect_sharp_area = false
  sharp_color = Vector3(1.0, 1.0, 1.0)
  sharp_gamma = 1.0
  sharp_contrast = 1.0
  perpipheral_color = Vector3(0.1, 0.1, 0.1)
  peripheral_gamma = 0.7
  peripheral_contrast = 0.2
  camera.set_auto_exposure()
  effects.set_glow({
    'strength': 1.0
  })
  if PlayerData.vega:
    PlayerData.vega.flashlight_mode("none")

func _on_night_vision_pressed() -> void:
  print("nvg toggle")
  match vision_mode:
    VisionMode.NORMAL:
      _set_nvg_2()
    VisionMode.NVG2:
      _set_nvg_3()
    VisionMode.NVG3:
      _set_normal_vision()
