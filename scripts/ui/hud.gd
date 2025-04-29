extends Control

func _process(_delta: float) -> void:
  $Debug.text = "%s" % GameState.debug_text
