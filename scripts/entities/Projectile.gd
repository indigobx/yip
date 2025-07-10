extends Node3D

var ammo: AmmoData
var velocity: Vector3
var frame: int = 0
@onready var zero_position = global_position
var distance = 0.0
@onready var debug_marker_scene = preload("res://resources/weapon_fx/debug_mesh.tscn")
var bullet_hole_scene = preload("res://resources/weapon_fx/bullet_hole_decal.tscn")
var marker_nodes: Array = []
var substeps = 4
const MAX_SUBSTEPS = 50


func _ready() -> void:
  substeps = clamp(ceil(ammo.speed), 1, MAX_SUBSTEPS)

func set_initial_direction(direction: Vector3) -> void:
  velocity = direction.normalized() * ammo.speed
  look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
  var sub_delta = delta / substeps
  for i in range(substeps):
    if _simulate_substep(sub_delta):
      return
  frame += 1
  if distance > 50:
    queue_free()
  if frame > 90:
    queue_free()

func _place_trail_marker(pos: Vector3) -> void:
  if !debug_marker_scene:
    return
  #GameState.game.fx.add_decal(debug_marker_scene, pos)
  GameState.game.fx.add_fx("marker", debug_marker_scene, pos)


func _hit_target(hit) -> void:
  GameState.game.fx.add_fx("decal", bullet_hole_scene, hit, randf_range(0.5, 1.5))
  var target = hit.collider.get_parent()
  if target.has_method("take_damage"):
    target.take_damage(5)
    print("%s damage to %s" % [5, target])
  queue_free()

func _simulate_substep(sub_delta: float) -> bool:
  Ballistics.update_projectile(self, sub_delta)
  distance = (global_position - zero_position).length()
  var from = global_position
  var to = from + velocity * sub_delta * 4
  var space_state := get_world_3d().direct_space_state
  var query := PhysicsRayQueryParameters3D.create(from, to)
  query.collide_with_areas = true
  query.collide_with_bodies = true
  #query.collision_mask = 1 << 9  # Layer 10

  var result = space_state.intersect_ray(query)
  if result:
    global_position = result.position
    print("Hit at %s" % result)
    _hit_target(result)
    return true

  # Нет столкновения — двигаемся
  global_position = to
  _place_trail_marker(global_position)
  return false
