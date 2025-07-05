extends Node3D

var effects_manager: Node
var projectiles: Node
var projectile = preload("res://scenes/weapons/Projectile.tscn")
var weapon: WeaponData
var ammo: AmmoData

func _ready() -> void:
#  InputHandler.connect("fire_pressed", Callable(self, "_on_fire_pressed"))
#  InputHandler.connect("fire_released", Callable(self, "_on_fire_released"))
  InputHandler.connect("fire_single", Callable(self, "_on_fire_single"))
#  InputHandler.connect("fire_charge", Callable(self, "_on_fire_charge"))
  effects_manager = get_tree().root.get_node("Main/Managers/EffectsManager")
  projectiles = get_tree().root.get_node("Main/Game/Projectiles")
  weapon = WeaponRegistry.get_weapon_by_name(PlayerData.selected_weapon_name)
  ammo = AmmoRegistry.get_ammo_by_name(weapon.ammo_type)

func _on_fire_single() -> void:
  var from = GameState.gun_muzzle_pos
  var to = GameState.cursor_world_pos
  #var direction = (to - from).normalized()  # direct
  var direction = Ballistics.get_aim_direction(from, to, ammo)


  var proj_instance = projectile.instantiate()
  proj_instance.ammo = ammo
  proj_instance.name = "%s_%s" % [
    ammo.name,
    str(randi()).md5_text()
  ]

  projectiles.add_child(proj_instance)
  proj_instance.global_position = from
  proj_instance.set_initial_direction(direction)

  print("%s is firing %s" % [weapon.name, proj_instance.name])
