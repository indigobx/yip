extends Node

@export var weapon_holder: Node3D
var current_weapon: Node3D = null

func _ready() -> void:
  _equip_from_data()
  _connect_signals()

func _equip_from_data() -> void:
  if current_weapon:
    current_weapon.queue_free()

  if PlayerData.selected_weapon:
    current_weapon = PlayerData.selected_weapon.instantiate()
    weapon_holder.add_child(current_weapon)

func _connect_signals() -> void:
  InputHandler.connect("fire_pressed", Callable(self, "_on_fire_pressed"))
  InputHandler.connect("fire_released", Callable(self, "_on_fire_released"))
  InputHandler.connect("fire_single", Callable(self, "_on_fire_single"))
  InputHandler.connect("fire_charge", Callable(self, "_on_fire_charge"))

func _on_fire_pressed() -> void:
  if current_weapon and current_weapon.has_method("fire_pressed"):
    current_weapon.fire_pressed()

func _on_fire_released() -> void:
  if current_weapon and current_weapon.has_method("fire_released"):
    current_weapon.fire_released()

func _on_fire_single() -> void:
  if current_weapon and current_weapon.has_method("fire_single"):
    current_weapon.fire_single()

func _on_fire_charge() -> void:
  if current_weapon and current_weapon.has_method("fire_charge"):
    current_weapon.fire_charge()
