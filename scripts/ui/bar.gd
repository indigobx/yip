extends HBoxContainer

var _value: float
var _max: float
@export var value: float = 0.0:
  get:
    return _value
  set(v):
    set_value(v)
@export var max: float = 100.0:
  get:
    return _max
  set(v):
    set_max(v)
@export var show_max: bool = true
var _type: String
@export var type: String = "health":
  get:
    return _type
  set(v):
    set_type(v)


func _ready() -> void:
  $ValueBar.min_value = 0.0
  set_type(type)
  set_value(value)
  set_max(max)
  if not show_max:
    $Max.visible = false

func set_value(v) -> void:
  _value = v
  $Value.text = "%.0f" % v
  $ValueBar.value = v


func set_max(v) -> void:
  _max = v
  $Max.text = "%.0f" % v
  $ValueBar.max_value = v


func set_type(v) -> void:
  _type = v
  $Icon/IconSprite.play(v)
