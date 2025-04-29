extends Area3D

@export_range(0.01, 500, 0.1) var distance_max: float = 200.0
@export_range(0, 180, 1.0, "radians_as_degrees") var fov_horizontal: float = PI / 6
@export_range(0, 180, 1.0, "radians_as_degrees") var fov_vertical: float = PI / 3

var detected_objects: Array[Node3D] = []
var shape: ConvexPolygonShape3D

func _ready() -> void:
  connect("body_entered", Callable(self, "_on_body_entered"))
  connect("body_exited", Callable(self, "_on_body_exited"))
  _build_fov_shape()

func _build_fov_shape() -> void:
  shape = ConvexPolygonShape3D.new()
  var points = _calc_fov_points()
  shape.points = points

  if collision_shape_exists():
    $CollisionShape3D.shape = shape
  else:
    var collision_shape = CollisionShape3D.new()
    collision_shape.shape = shape
    add_child(collision_shape)

func collision_shape_exists() -> bool:
  return has_node("CollisionShape3D")

func _calc_fov_points() -> Array[Vector3]:
  var far_point = Vector3(
    tan(fov_horizontal / 2) * distance_max,
    tan(fov_vertical / 2) * distance_max,
    distance_max
  )
  return [
    Vector3( far_point.x,  far_point.y, far_point.z),
    Vector3( far_point.x, -far_point.y, far_point.z),
    Vector3(-far_point.x,  far_point.y, far_point.z),
    Vector3(-far_point.x, -far_point.y, far_point.z),
    Vector3.ZERO
  ]

func _on_body_entered(body: Node3D) -> void:
  if not detected_objects.has(body):
    detected_objects.append(body)

func _on_body_exited(body: Node3D) -> void:
  detected_objects.erase(body)

func get_visible_objects() -> Array:
  var visible := []
  var space_state = get_world_3d().direct_space_state
  var from = global_transform.origin

  for body in detected_objects:
    if not is_instance_valid(body):
      continue

    var to = body.global_transform.origin
    var dir = (to - from)
    var dist = dir.length()

    if dist > distance_max:
      continue

    dir = dir.normalized()

    var local_dir = global_transform.basis.inverse() * dir

    # Проверка углов в локальных координатах
    var angle_h = atan2(local_dir.x, local_dir.z)
    var angle_v = atan2(local_dir.y, local_dir.z)

    if abs(angle_h) > fov_horizontal / 2.0:
      continue
    if abs(angle_v) > fov_vertical / 2.0:
      continue

    # Проверка прямой видимости
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]

    var result = space_state.intersect_ray(query)

    if result and result.collider == body:
      visible.append(body)

  return visible
