extends Node2D
class_name DamageText

@export var display_time := 1.0
@export var normal_color := Color(1.0, 1.0, 1.0)              # #FFFFFF
@export var critical_color := Color(0.89, 0.27, 0.35)         # #E34459
@export var ricochet_color := Color(0.57, 0.68, 1.0)          # #92AEFF
@export var penetration_color := Color(1.0, 0.58, 0.51)       # #FF947F
@export var fragmentation_color := Color(0.93, 0.85, 0.62)    # #EED99E

func setup(amount: float, is_critical: bool, hit_type: String) -> void:
  var display = _format_si(amount)
  $Damage.text = display["text"]
  $Damage.label_settings.font_size = display["font_size"]
  $Type.text = "%s" % hit_type if hit_type != "normal" else ""
  
  match hit_type:
    "penetration":
      $Damage.modulate = penetration_color
      $Type.modulate = penetration_color
    "ricochet":
      $Damage.modulate = ricochet_color
      $Type.modulate = ricochet_color
    "fragmentation":
      $Damage.modulate = fragmentation_color
      $Type.modulate = fragmentation_color
    _:
      $Damage.modulate = critical_color if is_critical else normal_color
      $Type.modulate = critical_color if is_critical else normal_color
    
  # Анимация всплывания
  var tween = create_tween()
  tween.tween_property(self, "position:y", position.y - 50, display_time)
  tween.parallel().tween_property(self, "modulate:a", 0.0, display_time)
  tween.tween_callback(queue_free)


func _format_si(value) -> Dictionary:
  var str: String
  var font_size: int
  if value < 1000:
    str = "%.1f J" % value
    font_size = 14
  elif value < 1000000:
    str = "%.1f KJ" % (value/1000.0)
    font_size = 18
  elif value < 1000000000:
    str = "%.1f MJ" % (value/1000000.0)
    font_size = 24
  else:
    str = "%.1f GJ" % (value/1000000000.0)
    font_size = 32
  return {
    "text": str,
    "font_size": font_size
  }
