extends Control

var bar_scene = preload("res://scenes/ui/bar.tscn")
@onready var health_bar = bar_scene.instantiate()
@onready var energy_bar = bar_scene.instantiate()

func _ready() -> void:
  energy_bar.connect("value_changed", _on_energy_value_changed)
  energy_bar.connect("max_changed", _on_energy_max_changed)
  health_bar.type = "health"
  health_bar.value = 100.0
  health_bar.max = 100.0
  energy_bar.type = "energy"
  energy_bar.value = 30.0
  energy_bar.max = 400.0
  $VBoxContainer.add_child(health_bar)
  $VBoxContainer.add_child(energy_bar)



func _process(_delta: float) -> void:
  pass


func _on_energy_value_changed() -> void:
  energy_bar.value = PlayerData.energy

func _on_energy_max_changed() -> void:
  energy_bar.max = PlayerData.energy_max
