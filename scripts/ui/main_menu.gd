extends Control

func _on_new_game_pressed() -> void:
  GameState.start_new_game()


func _on_quit_pressed() -> void:
  get_tree().quit()
