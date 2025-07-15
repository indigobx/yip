extends Node

const CONFIG_PATH := "user://controls.cfg"

var default_bindings := {
  "move_left": [KEY_A],
  "move_right": [KEY_D],
  "move_up": [KEY_W],
  "move_down": [KEY_S],
  "jump": [KEY_SPACE],
  "fire": [MOUSE_BUTTON_LEFT],
  "alt_fire": [MOUSE_BUTTON_RIGHT],
  "interact": [KEY_E],
  "zoom_in": [MOUSE_BUTTON_WHEEL_UP],
  "zoom_out": [MOUSE_BUTTON_WHEEL_DOWN],
  "night_vision": [KEY_N],
  "toggle_fire_mode": [KEY_T]
}

var max_ricochets: int = 3
var max_fragmentations: int = 1
var max_penetrations: int = 3
var total_impacts_limit: int = 5
var projectile_max_distance: float = 50.0
var projectile_max_substeps: int = 200
const max_recoil_offset = Vector3(0.15, 0.25, 0.1)  # X,Y,Z
const max_recoil_rotation = Vector2(0.5, 0.3)       # X (наклон), Y (поворот)

const debug_url = "http://127.0.0.1:58080"

func _ready():
  load_controls()

func load_controls():
  var config = ConfigFile.new()
  var err = config.load(CONFIG_PATH)

  if err != OK:
    print("⚠️ Не найден файл настроек, загружаем по умолчанию")
    apply_default_controls()
    return

  for action in default_bindings.keys():
    InputMap.action_erase_events(action)

    if config.has_section_key("input", action):
      var key_list = config.get_value("input", action, [])
      for key in key_list:
        var event := InputEventKey.new()
        event.physical_keycode = key
        InputMap.action_add_event(action, event)
    else:
      apply_default_action(action)

func save_controls():
  var config = ConfigFile.new()

  for action in default_bindings.keys():
    var events: Array = InputMap.action_get_events(action)
    var keycodes := []

    for event in events:
      if event is InputEventKey:
        keycodes.append(event.physical_keycode)

    config.set_value("input", action, keycodes)

  config.save(CONFIG_PATH)



func apply_default_controls():
  for action in default_bindings.keys():
    InputMap.action_erase_events(action)
    apply_default_action(action)

func apply_default_action(action: String):
  for key in default_bindings[action]:
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action, event)
