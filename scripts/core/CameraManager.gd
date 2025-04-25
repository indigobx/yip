extends Node3D

@export var fovs: Array[float] = [15.0, 30.0, 45.0]
@export var fov_base_index: int = 1  # индекс по умолчанию
@export var tween_speed := 0.5  # В секундах
@export var position_offset: Vector3 = Vector3(0.0, 20.0, 30.0)

@onready var camera: Camera3D = $Camera3D

var fov_index := 0
var tween: Tween = null
var target: Node3D = null

func _ready() -> void:
  fov_index = clamp(fov_base_index, 0, fovs.size() - 1)
  camera.make_current()
  InputHandler.set_camera(camera)
  InputHandler.connect("zoom_in", Callable(self, "_on_zoom_in"))
  InputHandler.connect("zoom_out", Callable(self, "_on_zoom_out"))
  _update_zoom()

func _process(_delta: float) -> void:
  if target and target.is_inside_tree():
    global_position = target.global_position + position_offset
    look_at(target.global_position)

func _on_zoom_in() -> void:
  fov_index = clamp(fov_index - 1, 0, fovs.size() - 1)
  _update_zoom()

func _on_zoom_out() -> void:
  fov_index = clamp(fov_index + 1, 0, fovs.size() - 1)
  _update_zoom()

func _update_zoom() -> void:
  var target_fov = fovs[fov_index]


  if tween and tween.is_running():
    tween.kill()

  tween = get_tree().create_tween()
  tween.tween_property(camera, "fov", target_fov, tween_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_target(new_target: Node3D) -> void:
  target = new_target
