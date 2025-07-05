extends Node3D

var ammo: AmmoData
var velocity: Vector3
var frame: int = 0

func set_initial_direction(direction: Vector3) -> void:
  velocity = direction.normalized() * ammo.speed
  look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
  Ballistics.update_projectile(self, delta)
  global_position += velocity * delta
  _check_raycast()
  frame += 1

  if frame > 90:
    queue_free()

func _check_raycast() -> void:
  if $RayCast3D.is_colliding():
    print("point: %s" % $RayCast3D.get_collision_point())
    _hit_target()

func _hit_target() -> void:
  print("normal: %s" % $RayCast3D.get_collision_normal())
  queue_free()
