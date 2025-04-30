extends Node

const CONFIG_PATH := "user://controls.cfg"

var default_bindings := {
  "move_left": [KEY_A],
  "move_right": [KEY_D],
  "move_up": [KEY_W],
  "move_down": [KEY_S],
  "jump": [KEY_SPACE],
  "fire": [MOUSE_BUTTON_LEFT],
  "interact": [KEY_E],
  "zoom_in": [MOUSE_BUTTON_WHEEL_UP],
  "zoom_out": [MOUSE_BUTTON_WHEEL_DOWN],
  "night_vision": [KEY_N]
}

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
