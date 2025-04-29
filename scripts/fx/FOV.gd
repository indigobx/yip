extends CanvasLayer

@onready var camera = get_tree().root.get_node("Main/Managers/CameraController/Camera3D")

func _process(delta: float) -> void:
  var shader_material = $FovRect.material as ShaderMaterial
  shader_material.set_shader_parameter("camera_global_transform", camera.global_transform)
  shader_material.set_shader_parameter("focus_point", GameState.focus_point)
  shader_material.set_shader_parameter("vision_point", GameState.vision_point)
  shader_material.set_shader_parameter("sharp_fov_deg", 45.0)
  shader_material.set_shader_parameter("peripheral_fov_deg", 120.0)
