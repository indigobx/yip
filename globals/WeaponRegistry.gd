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
    var weapon = parse_weapon_dict(entry)
    if weapon != null:
      weapon_dict[weapon.name] = weapon
      weapon_list.append(weapon)
      
  var out = "Loaded %s weapon data:" % len(weapon_list)
  for w in weapon_list:
    out += " %s," % w.name
  print(out.substr(0, len(out)-1) + ".")
      

func parse_weapon_dict(dict: Dictionary) -> WeaponData:
  var weapon = WeaponData.new()

  weapon.name = dict.get("name", "")
  weapon.mass = dict.get("mass", 0.0)
  weapon.barrel_length = dict.get("barrel_length", 0.0)
  weapon.recoil_strength = dict.get("recoil_strength", 1.0)
  weapon.ammo_type = dict.get("ammo_type", "")

  return weapon

func get_weapon_by_name(name: String) -> WeaponData:
  return weapon_dict.get(name, null)
