extends CharacterBody3D

@export var max_hp := 1000.0
@export var hp := 1000.0

func take_damage(damage) -> float:
  hp = clampf(hp - damage, 0.0, max_hp)
  #GameState.debug_text = "%s\ntook %.1f damage\n%.1f HP left" % [
    #name, damage, hp
  #]
  return hp
