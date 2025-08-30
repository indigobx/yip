extends Node

enum GameStates {
  BOOT,          # игра только запустилась, ещё ничего не инициализировано
  MAIN_MENU,     # главное меню
  LOADING,       # экран загрузки
  IN_LEVEL,      # игрок в уровне (геймплей активен)
  PAUSED,        # уровень поставлен на паузу (меню паузы)
  GAME_OVER,     # игрок проиграл
  EXITING        # выход из игры / завершение
}

var game_state: GameStates = GameStates.BOOT:
  set(value):
    if game_state == value:
      return
    game_state = value
    _on_game_state_changed(value)

signal game_state_changed(new_state)

func _ready():
  game_state = GameStates.BOOT

func _on_game_state_changed(new_state: GameStates) -> void:
  emit_signal("game_state_changed", new_state)

func start_new_game() -> void:
  game_state = GameStates.LOADING
  UIManager.hide_all("modal")
  UIManager.show(UIManager.UIKey.LOADING_SCREEN, "base")
  
  
