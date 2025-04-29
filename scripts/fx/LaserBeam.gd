extends Node3D

@export var target := Vector3.ZERO
@export var rotation_offset := Vector3.ZERO
@export var size: float = 0.5
@export var pulse: bool = false
@export var pulse_interval_min: float = 0.01
@export var pulse_interval_max: float = 0.05
var _color_center: Color = Color(1.0, 1.0, 2.0, 1.0)
var _color_mid: Color = Color(1.0, 0.8, 0.4, 0.4)
var _color_edge: Color = Color(0.5, 0.05, 0.0, 0.0) 
@export var color_center: Color:
  get:
    return _color_center
  set(value):
    _color_center = value
    _update_shader_settings()
@export var color_mid: Color:
  get:
    return _color_mid
  set(value):
    _color_mid = value
    _update_shader_settings()
@export var color_edge: Color:
  get:
    return _color_edge
  set(value):
    _color_edge = value
    _update_shader_settings()
@export var cubic_interpolation: bool = true

@onready var pulse_timer := Timer.new()
@onready var laser_material: ShaderMaterial = preload("res://resources/weapon_fx/laser_shader_material.tres")

func _ready() -> void:
  laser_material = laser_material.duplicate()
  $QuadMeshA.material_override = laser_material
  $QuadMeshB.material_override = laser_material
  _update_shader_settings()

  if pulse:
    pulse_timer.wait_time = pulse_interval_min
    pulse_timer.autostart = true
    pulse_timer.one_shot = false
    pulse_timer.timeout.connect(_on_pulse_timer_timeout)
    add_child(pulse_timer)

func _on_pulse_timer_timeout() -> void:
  pulse_timer.wait_time = _pulse()
  visible = not visible

func _process(_delta: float) -> void:
  _update_beam()

func _update_beam() -> void:
  var origin = global_transform.origin
  var direction = target - origin
  var length = direction.length()

  if length < 0.01:
    return  # Не стрелять в себя

  look_at(target, Vector3.UP)
  rotation += rotation_offset

  # Масштаб: по Y — длина, по X и Z — толщина луча
  scale = Vector3(size, size, length)

func _pulse() -> float:
  var pulse_duration = randf_range(pulse_interval_min, pulse_interval_max)
  return pulse_duration

func _update_shader_settings() -> void:
  if laser_material:
    laser_material.set_shader_parameter("center_color", color_center)
    laser_material.set_shader_parameter("mid_color", color_mid)
    laser_material.set_shader_parameter("edge_color", color_edge)
    laser_material.set_shader_parameter("cubic_interpolation", cubic_interpolation)
