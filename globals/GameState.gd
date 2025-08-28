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

var game_state: GameStates = GameStates.BOOT
