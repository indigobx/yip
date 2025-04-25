extends Decal

  

func _process(delta: float) -> void:
  if not $Timer.is_stopped():
    emission_energy = lerp(emission_energy, 0.0, 0.1)


func _on_timer_timeout() -> void:
  $Timer.queue_free()
  process_mode = Node.PROCESS_MODE_DISABLED
