extends HBoxContainer

var _value: float
var _max: float
@export var value: float = 0.0:
  get:
    return _value
  set(v):
    _value = v
    set_value(v)
@export var max: float = 100.0:
  get:
    return _max
  set(v):
    _max = v
    set_max(v)
@export var show_max: bool = true
var _type: String
@export var type: String = "health":
  get:
    return _type
  set(v):
    _type = v
    set_type(v)

signal max_changed
signal value_changed

func _ready() -> void:
  $ValueBar.min_value = 0.0
  set_type(type)
  set_value(value)
  set_max(max)
  if not show_max:
    $Max.visible = false

func set_value(v) -> void:
  $Value.text = "%.0f" % v
  $ValueBar.value = v
  emit_signal("value_changed")

func set_max(v) -> void:
  $Max.text = "%.0f" % v
  $ValueBar.max_value = v
  emit_signal("value_changed")

func set_type(v) -> void:
  $Icon/IconSprite.play(v)
