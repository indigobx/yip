extends Node

const YAML_PATH := "res://resources/weapons/weapon_data.yaml"
var weapon_dict: Dictionary = {}
var weapon_list: Array[WeaponData] = []

func _ready():
  load_weapon_from_yaml()

func load_weapon_from_yaml():
  var result = YAML.load_file(YAML_PATH)
  if result.has_error():
    push_error("YAML parse error: %s" % result.get_error())
    return

  var data = result.get_data()
  var entries: Array = data.get("weapons", [])

  weapon_dict.clear()
  weapon_list.clear()

  for entry in entries:
    var weapon = _safe_parse_weapon(entry)
    if weapon:
      weapon_dict[weapon.name] = weapon
      weapon_list.append(weapon)
  
  print_loaded_weapons()

func _safe_parse_weapon(dict: Dictionary) -> WeaponData:
  var weapon = WeaponData.new()
  
  # Основные параметры
  weapon.name = dict.get("name", "")
  weapon.mass = dict.get("mass", 0.0)
  weapon.barrel_length = dict.get("barrel_length", 0.0)
  weapon.recoil_strength = dict.get("recoil_strength", 1.0)
  weapon.ammo_type = dict.get("ammo_type", "")
  weapon.burst_rounds = dict.get("burst", 0)
  weapon.has_safety = dict.get("has_safety", true)
  
  # Параметры fire_rate с защитой
  var fire_rate = dict.get("fire_rate", {})
  if fire_rate is Dictionary:
    weapon.fire_rate_single = fire_rate.get("single", 0.0)
    weapon.fire_rate_auto = fire_rate.get("auto", 0.0)
    weapon.fire_rate_burst = fire_rate.get("burst", 0.0)
  
  return weapon

func print_loaded_weapons():
  var names = weapon_list.map(func(w): return w.name)
  print("Loaded weapons: ", ", ".join(names))

func get_weapon_by_name(wname: String) -> WeaponData:
  return weapon_dict.get(wname) as WeaponData
