extends Node3D

@onready var mat: StandardMaterial3D = $MeshInstance3D.get_active_material().duplicate()
var color = "white"

func _ready() -> void:
  set_color(color)

func set_color(c) -> void:
  mat.albedo_color = c
  mat.emission = c
  $MeshInstance3D.material_override = mat

  
