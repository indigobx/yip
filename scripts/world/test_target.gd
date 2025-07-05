extends Node3D

var textures = {
  "albedo_ok": preload("res://assets/environments/test_range/target_albedo_ok.png"),
  "albedo_hit": preload("res://assets/environments/test_range/target_albedo_hit.png"),
  "albedo_miss": preload("res://assets/environments/test_range/target_albedo_miss.png"),
  "emit_ok": preload("res://assets/environments/test_range/target_emit_ok.png"),
  "emit_hit": preload("res://assets/environments/test_range/target_emit_hit.png"),
  "emit_miss": preload("res://assets/environments/test_range/target_emit_miss.png")
}
var albedo: Texture2D
var emit: Texture2D
var emit_power_ok: float = 1.0
var emit_power_hit: float = 5.0
@onready var material: BaseMaterial3D = $Mesh.get_active_material(0)

func _ready() -> void:
  _set_ok()

func _on_area_3d_area_entered(area: Area3D) -> void:
  _set_hit()
  $Timer.start()

func _on_timer_timeout() -> void:
  _set_ok()

func _set_ok() -> void:
  material.albedo_texture = textures["albedo_ok"]
  material.emission_texture = textures["emit_ok"]
  material.emission_enabled = true
  material.emission_energy_multiplier = emit_power_ok

func _set_hit() -> void:
  material.albedo_texture = textures["albedo_hit"]
  material.emission_texture = textures["emit_hit"]
  material.emission_enabled = true
  material.emission_energy_multiplier = emit_power_hit
