extends Node

func _ready() -> void:
  GameState.game_state_changed.connect(_on_game_state_changed)
  print("stage_change conn")
  # UI
  UIManager.attach_root($UI)
  print("ui!")
  UIManager.show(UIManager.UIKey.MAIN_MENU, "modal")
  
  # Level Manager
  LevelManager.attach_world_root($World)
  Console.log("test")

func _on_game_state_changed(state) -> void:
  pass

func _process(_delta: float) -> void:
  pass
