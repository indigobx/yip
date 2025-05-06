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
var _type: int
@export var type: int = 0:
  get:
    return _type
  set(v):
    _type = v
    set_type(v)

func _ready() -> void:
  var tx = $Icon.texture.duplicate()
  $Icon.texture = tx
  $ValueBar.min_value = 0.0
  set_type(type)
  set_value(value)
  set_max(max)
  if not show_max:
    $Max.visible = false

func set_value(v) -> void:
  $Value.text = "%s" % v
  $ValueBar.value = v

func set_max(v) -> void:
  $Max.text = "%s" % v
  $ValueBar.max_value = v

func set_type(v) -> void:
  var xy = Vector2i(0, 0)
  var wh = Vector2i(24, 24)
  print("type is %s " % v)
  match v:
    0:
      xy = Vector2i(9, 10)
    1:
      xy = Vector2i(44, 10)
    2:
      xy = Vector2i(14, 37)
    3:
      xy = Vector2i(12, 67)
    4:
      xy = Vector2i(66, 67)
  $Icon.texture.region = Rect2i(xy, wh)
