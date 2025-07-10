extends Decal

@onready var preloader = $ResourcePreloader

func _ready():
  var texture_keys = preloader.get_resource_list()
  if texture_keys.size() > 0:
    var random_key = texture_keys[randi() % texture_keys.size()]
    texture_albedo = preloader.get_resource(random_key)


func _process(_delta: float) -> void:
  if not $Timer.is_stopped():
    emission_energy = lerp(emission_energy, 0.0, 0.1)


func _on_timer_timeout() -> void:
  $Timer.queue_free()
  texture_emission = null
  process_mode = Node.PROCESS_MODE_DISABLED
