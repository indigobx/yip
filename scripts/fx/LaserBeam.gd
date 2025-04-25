extends Node3D

@export var target := Vector3.ZERO
#@export var rotation_offset := Vector3(-PI / 2, 0, 0)
@export var rotation_offset := Vector3.ZERO
@export var size: float = 0.5

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
