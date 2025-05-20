extends Control

var bar_scene = preload("res://scenes/ui/bar.tscn")
@onready var health_bar = bar_scene.instantiate()
@onready var energy_bar = bar_scene.instantiate()

func _ready() -> void:
  health_bar.type = "health"
  health_bar.value = 100.0
  health_bar.max = 100.0
  energy_bar.type = "energy"
  energy_bar.value = 30.0
  energy_bar.max = 400.0
  $VBoxContainer.add_child(health_bar)
  $VBoxContainer.add_child(energy_bar)
  PlayerData.connect("health_changed", _on_health_changed)
  PlayerData.connect("health_max_changed", _on_health_max_changed)
  PlayerData.connect("energy_changed", _on_energy_changed)
  PlayerData.connect("energy_max_changed", _on_energy_max_changed)
  PlayerData.connect("damage_taken", _on_damage_taken)
  


func _process(_delta: float) -> void:
  pass

func _on_health_changed(v) -> void:
  health_bar.value = v

func _on_health_max_changed(v) -> void:
  health_bar.max = v

func _on_energy_changed(v) -> void:
  energy_bar.value = v

func _on_energy_max_changed(v) -> void:
  energy_bar.max = v


func _on_damage_taken() -> void:
  $Overlay/DamageFX/DamageTimer.start()
  $Overlay/DamageFX.visible = true


func _on_damage_timer_timeout() -> void:
  $Overlay/DamageFX.visible = false
