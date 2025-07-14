class_name WeaponData
extends Resource

@export var name: String = ""
@export var mass: float = 0.0
@export var barrel_length: float = 0.0
@export var spread_moa: float = 4.0
@export var ammo_type: String = ""
@export var fire_rate_single: float = 0.0
@export var fire_rate_auto: float = 0.0
@export var fire_rate_burst: float = 0.0
@export var burst_rounds: int = 0
@export var has_safety: bool = true
@export var recoil_pattern: Curve  # Кривая для управления паттерном отдачи
@export var recoil_damping := 0.8  # Демпфирование отдачи
