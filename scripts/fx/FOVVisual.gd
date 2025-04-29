extends Node3D

@export_range(0, 360, 1.0, "radians_as_degrees") var angle_horizontal: float = PI * 1/18
@export_range(0, 360, 1.0, "radians_as_degrees") var angle_vertical: float = PI * 1/3
@export_range(0.01, 100, 0.1) var distance_min = 0.1
@export_range(0.1, 500, 0.1) var distance_max = 200
@export var material: Material


var points: Array = []
var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh

func _ready() -> void:
  points = _calc_points()
  immediate_mesh = ImmediateMesh.new()
  mesh_instance = $MeshInstance3D
  mesh_instance.mesh = immediate_mesh
  mesh_instance.material_override = material
  _draw_mesh()

func _draw_mesh() -> void:
  immediate_mesh.clear_surfaces()
  immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

  # Рисуем треугольники

  # Near face
  _add_triangle(0, 1, 2)
  _add_triangle(1, 3, 2)

  # Far face
  _add_triangle(4, 6, 5)
  _add_triangle(5, 6, 7)

  # Right face
  _add_triangle(0, 4, 1)
  _add_triangle(1, 4, 5)

  # Left face
  _add_triangle(2, 3, 6)
  _add_triangle(3, 7, 6)

  # Top face
  _add_triangle(0, 2, 4)
  _add_triangle(2, 6, 4)

  # Bottom face
  _add_triangle(1, 5, 3)
  _add_triangle(3, 5, 7)

  immediate_mesh.surface_end()

func _add_triangle(i1: int, i2: int, i3: int) -> void:
  immediate_mesh.surface_add_vertex(points[i1])
  immediate_mesh.surface_add_vertex(points[i2])
  immediate_mesh.surface_add_vertex(points[i3])

func _calc_points() -> Array:
  var near_point = Vector3(
    tan(angle_horizontal/2) * distance_min,
    tan(angle_vertical/2) * distance_min,
    distance_min
  )
  var far_point = Vector3(
    tan(angle_horizontal/2) * distance_max,
    tan(angle_vertical/2) * distance_max,
    distance_max
  )
  return [
    Vector3( near_point.x,  near_point.y, near_point.z),
    Vector3( near_point.x, -near_point.y, near_point.z),
    Vector3(-near_point.x,  near_point.y, near_point.z),
    Vector3(-near_point.x, -near_point.y, near_point.z),
    Vector3( far_point.x,  far_point.y, far_point.z),
    Vector3( far_point.x, -far_point.y, far_point.z),
    Vector3(-far_point.x,  far_point.y, far_point.z),
    Vector3(-far_point.x, -far_point.y, far_point.z)
  ]

  
