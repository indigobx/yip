extends Node

enum Rifling { NONE, POLYGONAL, TRAPEZOID, RATCHET }
enum Medium {
  AIR_CLEAN,     # Чистый воздух
  AIR_URBAN,     # Городской воздух
  WATER,       # Вода
  VACUUM,      # Космический вакуум
  GEL,       # Биогель/плазма
  SOLID_ISOTROPIC  # Твердые тела (упрощенная модель)
}

const MEDIUM_PROFILES = {
  Medium.AIR_CLEAN: {
    "density_func": "_calc_gas_density",
    "base_density": 1.225,
    "drag_model": "quadratic",
    "drag_coef": 1.0,
    "viscosity": 1.8e-5
  },
  Medium.WATER: {
    "density_func": "_calc_liquid_density",
    "base_density": 997.0,
    "drag_model": "stokes",
    "drag_coef": 50.0,
    "viscosity": 0.001
  },
  Medium.VACUUM: {
    "base_density": 1e-12,
    "drag_model": "none"
  }
}


func get_medium(medium: Medium) -> Dictionary:
  return MEDIUM_PROFILES.get(medium, MEDIUM_PROFILES[Medium.AIR_CLEAN])

func get_medium_density(medium: Medium, temp: float, pressure: float = -1.0) -> float:
  var profile = get_medium(medium)
  if profile.has("base_density"):
    return profile.base_density
  return call(profile.density_func, temp, pressure)


var _safe_chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
var _safe_chars_len = _safe_chars.length()

func gen_uid(length: int = 8, prefix: String = "", suffix: String = "") -> String:
  var result = PackedByteArray()
  result.resize(length)
  for i in range(length):
    result[i] = _safe_chars.unicode_at(randi() % _safe_chars_len)
  return prefix + result.get_string_from_ascii() + suffix
