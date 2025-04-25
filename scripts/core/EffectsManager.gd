extends Node3D

var max_decals = 300

func add_decal(decal, hit, scale:float=1.0) -> void:
  var decal_instance = decal.instantiate()
  $Decals.add_child(decal_instance)
  decal_instance.scale = Vector3(scale, scale, scale)
  decal_instance.global_position = hit.position
  decal_instance.rotation = hit.position + hit.normal
  cleanup_decals()

func cleanup_decals() -> void:
  var decals_count = $Decals.get_child_count()
  if decals_count > max_decals:
    var first_decal = $Decals.get_child(0)
    first_decal.queue_free()
