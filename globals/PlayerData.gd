extends Node

var selected_weapon: PackedScene = preload("res://scenes/weapons/BeamGun.tscn")
var pregnancy_stage: int = 2
var vega: Node3D
var ev: float = 0.0

var health: float = 100.0
var health_max: float = 100.0
var energy: float = 0.0
var energy_max: float = 400.0
