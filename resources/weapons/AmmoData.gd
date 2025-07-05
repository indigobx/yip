class_name AmmoData
extends Resource

enum StabilizationType { NONE, SPIN, FIN, THRUST }

@export var name: String
@export var speed: float
@export var mass: float
@export var caliber: float
@export var drag_coef: float
@export var stab_type: StabilizationType = StabilizationType.NONE
@export var has_thruster: bool = false
@export var thrust_force: float = 0.0
@export var fuel_mass: float = 0.0
@export var burn_time: float = 0.0

# Дополнительно для пробиваемости:
@export var core_mass: float = 0.0
@export var core_hardness: float = 1.0
@export var core_caliber: float = 0.0

# Параметры рикошета (в градусах)
@export var ricochet_min_angle: float = 20.0
@export var ricochet_max_angle: float = 75.0
