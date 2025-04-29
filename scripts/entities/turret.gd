extends CharacterBody3D

@export var angle_a: float = -60.0
@export var angle_b: float = 60.0
@export var sweep_speed: float = 90.0  # градусов в секунду
@export var aim_speed: float = 60.0
@export var cooldown: float = 0.25

var _sweep_direction := 1  # 1 = вправо, -1 = влево

enum TurretState { SEARCHING, AIMING, FIRING, COOLDOWN }
var state: TurretState = TurretState.SEARCHING
var aim_target: Node3D = null

var beam_scene = preload("res://scenes/fx/laser.tscn")

@onready var aim_h = $Head
@onready var aim_v = $Head/BarrelPivot
@onready var muzzle = $Head/BarrelPivot/Barrel/Muzzle
@onready var scanner = $Body/Sensor/FOVSensor

func _ready() -> void:
  pass


func _process(delta: float) -> void:
  match state:
    TurretState.SEARCHING:
      _sweep_sensor(delta)
    TurretState.AIMING:
      _aim(delta)
    TurretState.FIRING:
      var target = _raycast_from_muzzle()
      if target and target.collider.name == "Vega":
        _attack(target)
        _change_state(TurretState.COOLDOWN)
    TurretState.COOLDOWN:
      _cooldown()

func _attack(target):
  var beam_instance = beam_scene.instantiate()
  beam_instance.size = 0.25
  beam_instance.pulse = true
  beam_instance.pulse_interval_min = 0.01
  beam_instance.pulse_interval_max = 0.05
  beam_instance.color_center = Color(5.0, 5.0, 12.0, 1.0)
  beam_instance.color_mid = Color(1.0, 0.8, 0.4, 0.2)
  beam_instance.cubic_interpolation = false
  add_child(beam_instance)
  beam_instance.global_position = muzzle.global_position
  beam_instance.target = target.position
  $HitLight.global_position = target.position
  $HitParticles.global_position = target.position
  $HitLight.visible = true
  $HitParticles.emitting = true
  await get_tree().create_timer(0.25).timeout
  $HitLight.visible = false
  $HitParticles.emitting = false
  beam_instance.queue_free()

func _raycast_from_muzzle(distance: float = 500.0) -> Dictionary:
  var space_state = get_world_3d().direct_space_state
  var origin = muzzle.global_transform.origin
  var direction = muzzle.global_transform.basis.z
  var to = origin + direction * distance
  
  var query = PhysicsRayQueryParameters3D.create(origin, to)
  query.collide_with_areas = false
  query.collide_with_bodies = true
  
  var result = space_state.intersect_ray(query)
  return result


func _cooldown() -> void:
  $CooldownTimer.start(cooldown)


func _aim(delta: float) -> void:
  if not aim_target or not is_instance_valid(aim_target):
    _change_state(TurretState.SEARCHING)
    return

  var from = global_transform.origin
  var to = aim_target.global_transform.origin
  var dir = to - from
  
  var dir_h = dir
  dir_h.y = 0
  dir_h = dir_h.normalized()
  var target_angle_h = atan2(dir_h.x, dir_h.z)
  var current_angle_h = aim_h.global_rotation.y
  var angle_diff_h = wrapf(target_angle_h - current_angle_h, -PI, PI)
  var step_h = deg_to_rad(aim_speed) * delta
  if abs(angle_diff_h) > step_h:
    aim_h.global_rotation.y += step_h * sign(angle_diff_h)
  else:
    aim_h.global_rotation.y = target_angle_h
  
  var aligned_h = abs(wrapf(
    target_angle_h - aim_h.global_rotation.y, -PI, PI
  )) < deg_to_rad(0.2)
  
  if aligned_h:
    _change_state(TurretState.FIRING)


func _sweep_sensor(delta: float) -> void:
  var sensor = $Body/Sensor
  if not sensor:
    return
  sensor.rotation_degrees.y += sweep_speed * delta * _sweep_direction
  # Проверяем границы
  if _sweep_direction > 0 and sensor.rotation_degrees.y >= angle_b:
    sensor.rotation_degrees.y = angle_b
    _sweep_direction = -1
  elif _sweep_direction < 0 and sensor.rotation_degrees.y <= angle_a:
    sensor.rotation_degrees.y = angle_a
    _sweep_direction = 1


func _change_state(new_state:TurretState) -> void:
  state = new_state


func _on_fov_sensor_body_entered(body: Node3D) -> void:
  if $CooldownTimer.is_stopped():
    if body and body.name == "Vega":
      aim_target = body
      _change_state(TurretState.AIMING)


func _on_fov_sensor_body_exited(body: Node3D) -> void:
  if body and body.name == "Vega":
    aim_target = null
    _change_state(TurretState.SEARCHING)


func _on_cooldown_timer_timeout() -> void:
  _change_state(TurretState.SEARCHING)
