extends Node3D

@export var max_distance := 1000.0
@export var damage := 5
@export var charged_damage := 20

var is_firing := false


func _ready() -> void:
  InputHandler.connect("fire_pressed", Callable(self, "_on_fire_pressed"))
  InputHandler.connect("fire_released", Callable(self, "_on_fire_released"))
  InputHandler.connect("fire_single", Callable(self, "_on_fire_single"))
  InputHandler.connect("fire_charge", Callable(self, "_on_fire_charge"))

func _on_fire_pressed() -> void:
  if not is_firing:
    is_firing = true
    _start_beam()

func _on_fire_released() -> void:
  if is_firing:
    is_firing = false
    _stop_beam()

func _on_fire_single() -> void:
  _update_beam()

func _on_fire_charge() -> void:
  _update_beam()

func _start_beam() -> void:
  $BeamParticles.emitting = true
  _update_beam()

func _stop_beam() -> void:
  $BeamParticles.emitting = false

func _process(_delta: float) -> void:
  if is_firing:
    _update_beam()

func _update_beam() -> void:
  var from = GameState.gun_muzzle_pos
  var to = GameState.cursor_world_pos
  var direction = (to - from).normalized()
  var hit = _raycast(from, direction)
  print(from, '  ', to, '  ', hit)

  $BeamParticles.look_at(hit)
  var middle = (from - hit) / 2
  #$Beam.mesh.center_offset = hit



func _raycast(from: Vector3, dir: Vector3) -> Vector3:
  var space_state = get_world_3d().direct_space_state
  var to = from + dir * max_distance
  var query := PhysicsRayQueryParameters3D.create(from, to)
  var result = space_state.intersect_ray(query)
  return result.position if result else to


func _apply_damage(hit_point: Vector3, dmg: float) -> void:
  # сюда вставишь логику повреждения, если попадёт в врага или объект
  pass

func _spawn_hit_effect(pos: Vector3) -> void:
  # Particles, Decals, Flash и т.п.
  pass
