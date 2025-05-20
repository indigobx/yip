extends Node

signal health_changed(new_health: float)
signal health_max_changed(new_max_health: float)
signal energy_changed(new_energy: float)
signal energy_max_changed(new_max_enegy: float)
signal damage_taken()
signal die()

var selected_weapon: PackedScene = preload("res://scenes/weapons/BeamGun.tscn")
var pregnancy_stage: int = 2
var vega: Node3D
var ev: float = 0.0

var _health: float = 100.0
var _health_max: float = 100.0
var _energy: float = 0.0
var _energy_max: float = 400.0

var health:
  get:
    return _health
  set(v):
    _health = v
    emit_signal("health_changed", v)
var health_max:
  get:
    return _health_max
  set(v):
    _health_max = v
    emit_signal("health_max_changed", v)
var energy:
  get:
    return _energy
  set(v):
    _energy = v
    emit_signal("energy_changed", v)
var energy_max:
  get:
    return _energy_max
  set(v):
    _energy_max = v
    emit_signal("energy_max_changed", v)

func take_damage(damage) -> void:
  var new_health = clamp(health-damage, 0.0, health_max)
  health = new_health
  emit_signal("damage_taken")
  if new_health <= 0.0:
    emit_signal("die")
