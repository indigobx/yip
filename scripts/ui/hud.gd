extends Control

var bar_scene = preload("res://scenes/ui/bar.tscn")


func _ready() -> void:
  var health_bar = bar_scene.instantiate()
  var energy_bar = bar_scene.instantiate()
  health_bar.type = 0
  health_bar.value = 100.0
  health_bar.max = 100.0
  energy_bar.type = 2
  energy_bar.value = 30.0
  energy_bar.max = 400.0
  $VBoxContainer.add_child(health_bar)
  $VBoxContainer.add_child(energy_bar)


func _process(_delta: float) -> void:
  pass
