extends Node3D
class_name Projectile

# Preloads
var projectile_scene = preload("res://scenes/weapons/Projectile.tscn")
var debug_marker_scene = preload("res://resources/weapon_fx/debug_mesh.tscn")
var debug_marker_red = preload("res://resources/weapon_fx/debug_mesh_red.tscn")
var debug_marker_blue = preload("res://resources/weapon_fx/debug_mesh_blue.tscn")
var bullet_hole_scene = preload("res://resources/weapon_fx/bullet_hole_decal.tscn")

# Projectile properties
var ammo: AmmoData
var velocity: Vector3
@onready var zero_position = global_position
var distance = 0.0
var substeps = 4
var total_substeps = 0

# Impact counters
var impact_count: int = 0
var ricochet_count: int = 0
var fragmentation_count: int = 0
var penetration_count: int = 0

# Debug system
var debug_id: String
var parent_debug_id: String = ""
var child_projectiles: Array = []
var debug_data = {
  "ammo_name": "",
  "initial_position": Vector3.ZERO,
  "substeps": []
}

func _ready() -> void:
  substeps = clamp(ceil(ammo.speed), 1, Config.projectile_max_substeps)
  debug_id = "proj_%s_%s" % [ammo.name, Time.get_ticks_msec()]
  _debug_save_init()

func _debug() -> void:
  print("impact %s\nricochet %s\nfragmentation %s\npenetration %s" % [
    impact_count, ricochet_count, fragmentation_count, penetration_count
  ])

func _debug_save_init() -> void:
  debug_data = {
    "ammo_name": ammo.name,
    "initial_position": {
      "x": zero_position.x,
      "y": zero_position.y,
      "z": zero_position.z
    },
    "substeps": []
  }

func _debug_save_substep(step: int) -> void:
  var substep_data = {
    "step": step,
    "position": {
      "x": global_position.x,
      "y": global_position.y,
      "z": global_position.z
    },
    "velocity": {
      "x": velocity.x,
      "y": velocity.y,
      "z": velocity.z
    },
    "distance": distance,
    "id": debug_id,
    "time": Time.get_unix_time_from_system(),
    "physics_frame": Engine.get_physics_frames(),
    "draw_frame": Engine.get_frames_drawn(),
    "impact_count": impact_count,
    "ricochet_count": ricochet_count,
    "fragmentation_count": fragmentation_count,
    "penetration_count": penetration_count,
    "ammo_properties": {
      "mass": ammo.mass,
      "caliber": ammo.caliber,
      "core_mass": ammo.core_mass,
      "core_caliber": ammo.core_caliber,
      "drag_coef": ammo.drag_coef
    }
  }
  debug_data["substeps"].append(substep_data)

func _debug_save_finalize() -> void:
  var final_data = {
    "id": debug_id,
    "parent_id": parent_debug_id,
    "ammo_data": debug_data,
    "children": child_projectiles.map(func(p): return p.debug_id if is_instance_valid(p) else "")
  }
  
  var file_path = "/Users/uzuri/Documents/Projects/yip-debug/data/%s-%s.json" % [debug_id, Time.get_unix_time_from_system()]
  var file = FileAccess.open(file_path, FileAccess.WRITE)
  if file:
    file.store_string(JSON.stringify(final_data, "  "))
    print("Saved debug data for ", debug_id)
  else:
    push_error("Failed to save debug data: ", FileAccess.get_open_error())
  
  for child in child_projectiles:
    if is_instance_valid(child):
      child._debug_save_finalize()

func set_initial_direction(direction: Vector3) -> void:
  velocity = direction.normalized() * ammo.speed
  look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
  var sub_delta = delta / substeps
  for i in range(substeps):
    total_substeps += 1
    _debug_save_substep(i)
    if _simulate_substep(sub_delta):
      break
  
  if distance > Config.projectile_max_distance or total_substeps > Config.projectile_max_substeps:
    _die()

func _simulate_substep(sub_delta: float) -> bool:
  Ballistics.update_projectile(self, sub_delta)
  distance = (global_position - zero_position).length()
  
  var from = global_position
  var to = from + velocity * sub_delta * 4
  var space_state := get_world_3d().direct_space_state
  var query := PhysicsRayQueryParameters3D.create(from, to)
  query.collide_with_areas = true
  query.collide_with_bodies = true

  var result = space_state.intersect_ray(query)
  if result:
    global_position = result.position
    _handle_impact(result)
    return true

  global_position = to
  if GameState.game and GameState.game.fx:
    var sc = debug_marker_scene
    if ricochet_count > 0:
      sc = debug_marker_red
    if fragmentation_count > 0:
      sc = debug_marker_blue
    GameState.game.fx.add_fx("marker", sc, global_position)
  return false

func _handle_impact(hit_result: Dictionary) -> void:
  impact_count += 1
  
  if impact_count >= Config.total_impacts_limit:
    _finalize_impact(hit_result)
    return
  
  if ammo.explosive and _should_explode(hit_result):
    _handle_explosion(hit_result["position"])
    return
  
  if penetration_count < Config.max_penetrations and _check_penetration(hit_result):
    _handle_penetration(hit_result)
    return
  
  if ricochet_count < Config.max_ricochets and _should_ricochet(hit_result["normal"]):
    _handle_ricochet(hit_result)
  elif fragmentation_count < Config.max_fragmentations and _should_fragment():
    _handle_fragmentation(hit_result)
  else:
    _finalize_impact(hit_result)

func _should_explode(hit_result: Dictionary) -> bool:
  if not ammo.explosive:
    return false
  
  var dist_traveled = distance
  if dist_traveled < ammo.fuse_arm_distance:
    return false
  
  var angle = rad_to_deg(acos(hit_result["normal"].dot(-velocity.normalized())))
  return angle <= ammo.fuse_init_angle

func _handle_explosion(pos: Vector3) -> void:
  if GameState.game and GameState.game.fx:
    GameState.game.fx.add_explosion(pos, ammo.explosive_mass * ammo.explosive_coef)
  
  var explosion_energy = 0.5 * ammo.mass * velocity.length_squared()
  var explosion_radius = ammo.explosive_mass * 0.5
  
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsShapeQueryParameters3D.new()
  query.shape = SphereShape3D.new()
  query.shape.radius = explosion_radius
  query.transform = Transform3D.IDENTITY.translated(pos)
  
  var results = space_state.intersect_shape(query)
  for result in results:
    if result.collider.has_method("take_energy_damage"):
      var dist_factor = 1.0 - (pos.distance_to(result.collider.global_position) / explosion_radius)
      result.collider.take_energy_damage(explosion_energy * dist_factor)
  
  if ammo.fragments_max > 0:
    _spawn_fragments(pos)
  
  _die()

func _spawn_fragments(pos: Vector3) -> void:
  var fragments_count = randi_range(ammo.fragments_min, ammo.fragments_max)
  var fragment_mass = ammo.core_mass / fragments_count * 0.7
  
  for i in range(fragments_count):
    var angle = randf_range(-180, 180)
    var new_dir = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(angle))
    var new_proj = _spawn_new_projectile(pos, new_dir, _create_fragment_ammo())
    new_proj.velocity = new_dir * velocity.length() * 0.6

func _create_fragment_ammo() -> AmmoData:
  var fragment_ammo = ammo.duplicate()
  fragment_ammo.mass = ammo.core_mass / ammo.fragments_max * 0.7
  fragment_ammo.core_mass = fragment_ammo.mass * 0.9
  fragment_ammo.caliber = ammo.caliber * 0.5
  fragment_ammo.core_caliber = ammo.core_caliber * 0.5
  fragment_ammo.drag_coef *= 2.5
  return fragment_ammo

func _check_penetration(hit_result: Dictionary) -> bool:
  if not hit_result["collider"].has_method("get_armor_thickness"):
    return false
    
  var armor_thickness = hit_result["collider"].get_armor_thickness(hit_result["position"])
  var penetration_required = armor_thickness * (1.0 - ammo.core_hardness)
  return _get_penetration_power() >= penetration_required

func _get_penetration_power() -> float:
  var core_energy = 0.5 * ammo.core_mass * velocity.length_squared()
  var cross_section = PI * pow(ammo.core_caliber * 0.5, 2)
  return core_energy / cross_section

func _handle_penetration(hit_result: Dictionary) -> void:
  penetration_count += 1
  ammo.caliber *= 1.1
  ammo.core_caliber *= 0.95
  ammo.mass *= 0.9
  ammo.core_mass *= 0.95
  
  global_position = hit_result["position"] + velocity.normalized() * 0.1
  apply_damage(hit_result["collider"], hit_result["position"], hit_result["normal"])
  velocity *= 0.8

func _should_ricochet(hit_normal: Vector3) -> bool:
  if !ammo.can_ricochet:
    return false
  
  var angle = rad_to_deg(acos(hit_normal.dot(-velocity.normalized())))
  if angle <= ammo.ricochet_min_angle:
    return false
  if angle >= ammo.ricochet_max_angle:
    return true
  
  var probability = ammo.ricochet_chance * (angle / ammo.ricochet_max_angle)
  return randf() < probability

func _handle_ricochet(hit_result: Dictionary) -> void:
  ricochet_count += 1
  apply_damage(hit_result["collider"], hit_result["position"], hit_result["normal"])
  ammo.caliber *= 1.1
  ammo.core_caliber *= 0.9
  ammo.mass *= 0.75
  
  var new_dir = velocity.normalized().bounce(hit_result["normal"])
  var new_proj = _spawn_new_projectile(hit_result["position"], new_dir, ammo.duplicate())
  new_proj.velocity = new_dir * velocity.length() * 0.5
  _die()

func _should_fragment() -> bool:
  return (ammo.fragmentation_chance > 0 and 
          ammo.fragments_min > 0 and 
          randf() < ammo.fragmentation_chance)

func _handle_fragmentation(hit_result: Dictionary) -> void:
  fragmentation_count += 1
  apply_damage(hit_result["collider"], hit_result["position"], hit_result["normal"])
  _spawn_fragments(hit_result["position"])
  _die()

func _finalize_impact(hit_result: Dictionary) -> void:
  apply_damage(hit_result["collider"], hit_result["position"], hit_result["normal"])
  if GameState.game and GameState.game.fx:
    GameState.game.fx.add_fx("decal", bullet_hole_scene, hit_result, randf_range(0.5, 1.5))
  _die()

func apply_damage(target, hit_position: Vector3, hit_normal: Vector3) -> void:
  var damage = _calculate_damage(hit_normal)
  var hit_type = _get_hit_type()
  var is_target = target.has_method("take_damage")
  
  if GameState.game and GameState.game.fx:
    GameState.game.fx.show_damage(
      hit_position,
      damage,
      hit_type,
      is_target
    )
  
  if is_target:
    target.take_damage(damage)

func _calculate_damage(hit_normal: Vector3) -> float:
  var kinetic_energy = 0.5 * ammo.mass * velocity.length_squared()
  var angle_factor = abs(hit_normal.dot(-velocity.normalized()))
  var distance_factor = min(1.0, 1.0 - distance / (ammo.effective_range if "effective_range" in ammo else 2000.0))
  return kinetic_energy * angle_factor * distance_factor

func _get_hit_type() -> String:
  if penetration_count > 0:
    return "penetration"
  if ricochet_count > 0:
    return "ricochet"
  if fragmentation_count > 0:
    return "fragmentation"
  return "normal"

func _spawn_new_projectile(pos: Vector3, dir: Vector3, new_ammo: AmmoData) -> Projectile:
  var new_proj = projectile_scene.instantiate()
  new_proj.ammo = new_ammo
  new_proj.parent_debug_id = debug_id
  child_projectiles.append(new_proj)
  
  new_proj.impact_count = impact_count
  new_proj.ricochet_count = ricochet_count
  new_proj.fragmentation_count = fragmentation_count
  new_proj.penetration_count = penetration_count
  
  var projectiles_node = get_tree().root.get_node_or_null("Main/Game/Projectiles")
  if projectiles_node:
    projectiles_node.add_child(new_proj)
    new_proj.global_position = pos
    new_proj.set_initial_direction(dir)
  return new_proj

func _die() -> void:
  _debug_save_finalize()
  queue_free()
