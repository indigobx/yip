extends Node3D

@export var max_distance := 1000.0
@export var damage := 5
@export var charge_max := 300.0
@export var charge := 0.0
@export var discharge_rate := 50.0
@export var first_shot_discharge := 20.0
@export var minimum_charge := 30.0
@export var recharge_rate := 50.0

var is_firing := false
var beam_scene = preload("res://scenes/fx/laser.tscn")
var beam_instance
var laser_blast = preload("res://resources/weapon_fx/laser_blast_decal.tscn")

var effects_manager

func _ready() -> void:
  InputHandler.connect("fire_pressed", Callable(self, "_on_fire_pressed"))
  InputHandler.connect("fire_released", Callable(self, "_on_fire_released"))
  InputHandler.connect("fire_single", Callable(self, "_on_fire_single"))
  InputHandler.connect("fire_charge", Callable(self, "_on_fire_charge"))
  effects_manager = get_tree().root.get_node("Main/Managers/EffectsManager")

func _on_fire_pressed() -> void:
  if charge >= minimum_charge and not is_firing:
    charge -= first_shot_discharge
    is_firing = true
    _start_beam()


func _on_fire_released() -> void:
  if is_firing:
    is_firing = false
    _stop_beam()


#func _on_fire_single() -> void:
  #is_firing = true
  #_start_beam()
  #await get_tree().create_timer(0.1).timeout
  #is_firing = false
  #_stop_beam()

#func _on_fire_charge() -> void:
  #_update_beam()

func _start_beam() -> void:
  beam_instance = beam_scene.instantiate()
  beam_instance.size = 0.25
  beam_instance.pulse = true
  beam_instance.pulse_interval_min = 0.01
  beam_instance.pulse_interval_max = 0.05
  beam_instance.color_center = Color(5.0, 5.0, 12.0, 1.0)
  beam_instance.color_mid = Color(1.0, 0.8, 0.4, 0.2)
  beam_instance.cubic_interpolation = false
  add_child(beam_instance)
  $HitParticles.emitting = true
  $MuzzleParticles.emitting = true
  $Lights.visible = true
  _update_beam()

func _stop_beam() -> void:
  $HitParticles.emitting = false
  $MuzzleParticles.emitting =  false
  $Lights.visible = false
  if beam_instance:
    beam_instance.queue_free()

func _physics_process(delta: float) -> void:
  if charge <= 0.0:
    is_firing = false
    _stop_beam()
  if is_firing:
    _update_beam()
    charge = clampf(charge - discharge_rate*delta, 0.0, charge_max)
  if not is_firing:
    charge = clampf(charge + recharge_rate*delta, 0.0, charge_max)
  GameState.debug_text = "Charge %.1f" % [charge]


func _update_beam() -> void:
  var from = GameState.gun_muzzle_pos
  var to = GameState.cursor_world_pos
  var direction = (to - from).normalized()
  var raycast = _raycast(from, direction)
  var hit = raycast.position if raycast else to
  #print(from, '  ', to, '  ', hit)
  
  beam_instance.global_position = from
  beam_instance.target = hit
  _spawn_hit_effect(raycast, direction)
  $MuzzleParticles.global_position = from
  $MuzzleParticles.look_at(hit)
  $Lights/MuzzleLight.global_position = from
  $Lights/HitLight.global_position = hit - direction
  beam_instance.color_center = Color(
    randf_range(0.9, 1.1), randf_range(0.9, 1.1), randf_range(1.8, 2.2)
  )
  if not beam_instance.visible:
    $Lights/MuzzleLight.light_energy = 0.9
    $Lights/MuzzleLight.light_color = "#fca"
    $Lights/HitLight.light_color = "#f63"
  else:
    $Lights/MuzzleLight.light_energy = 0.5
    $Lights/MuzzleLight.light_color = "#f84"
    $Lights/HitLight.light_color = "#faa"
  
  if raycast.collider and raycast.collider.has_method("take_damage"):
    var damage_angle_mod = raycast.normal.angle_to(from)/PI
    var target_hp = raycast.collider.take_damage(damage * damage_angle_mod)


func _raycast(from: Vector3, dir: Vector3) -> Dictionary:
  var space_state = get_world_3d().direct_space_state
  var to = from + dir * max_distance
  var query := PhysicsRayQueryParameters3D.create(from, to)
  var result = space_state.intersect_ray(query)
  return result if result else null


func _apply_damage(hit_point: Vector3, dmg: float) -> void:
  # сюда вставишь логику повреждения, если попадёт в врага или объект
  pass

func _spawn_hit_effect(raycast: Dictionary, direction: Vector3) -> void:
  $HitParticles.global_position = raycast.position
  $HitParticles.process_material.direction = (raycast.normal - direction)/2
  effects_manager.add_decal(laser_blast, raycast, 0.5)
