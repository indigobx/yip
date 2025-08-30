extends Node
## LevelManager.gd — менеджер загрузки уровней (autoload).
## Ответственность:
## - асинхронная загрузка PackedScene (ResourceLoader threaded)
## - показ/скрытие экрана загрузки через UIManager
## - инстанс уровня в переданный WorldRoot (из main.gd)
## - прогресс и события загрузки
## - безопасная выгрузка/перезагрузка

# --- Настройки / публичные поля ---

@export var show_loading_screen: bool = true      # показывать ли экран загрузки
@export var auto_fade_loading: bool = true        # быстро гасить загрузчик при завершении
@export var first_frame_warmup_ms: int = 16       # "прогрев" перед гашением загрузчика

# Псевдо-веса этапов прогресса
@export var weight_prepare: float = 0.10
@export var weight_request: float = 0.05
@export var weight_stream: float = 0.70
@export var weight_instantiate: float = 0.10
@export var weight_post: float = 0.05

# --- Сигналы ---

signal level_loading_started(path: String)
signal level_loading_progress(path: String, progress: float, status: StringName)
signal level_ready(path: String, level_instance: Node)
signal level_unloaded(prev_path: String)
signal level_error(path: String, message: String)

# --- Внутреннее состояние ---

var _world_root: Node
var _current_level: Node
var _current_level_path: String = ""
var _pending_path: String = ""
var _pending_params: Dictionary = {}   # <- типизировано; вместо meta
var _loading: bool = false
var _cancel_requested: bool = false

# трекинг прогресса
var _p_prepare: float = 0.0
var _p_request: float = 0.0
var _p_stream: float = 0.0
var _p_instant: float = 0.0
var _p_post: float = 0.0
var _last_status: StringName = &""

# --- Публичный API ---

func attach_world_root(root: Node) -> void:
  _world_root = root
  process_mode = Node.PROCESS_MODE_ALWAYS

func is_loading() -> bool:
  return _loading

func current_level() -> Node:
  return _current_level

func current_path() -> String:
  return _current_level_path

func get_progress() -> float:
  var total_weight := weight_prepare + weight_request + weight_stream + weight_instantiate + weight_post
  if total_weight <= 0.0:
    total_weight = 1.0
  var sum := _p_prepare * weight_prepare \
    + _p_request * weight_request \
    + _p_stream * weight_stream \
    + _p_instant * weight_instantiate \
    + _p_post * weight_post
  return clamp(sum / total_weight, 0.0, 1.0)

func can_quit_now() -> bool:
  if _loading:
    return false
  if is_instance_valid(_current_level) and _current_level.has_method("can_quit_now"):
    return bool(_current_level.call("can_quit_now"))
  return true

## Запуск загрузки
func load_level(path: String, params: Dictionary = {}) -> void:
  if path == "":
    push_error("LevelManager.load_level: пустой путь")
    return

  if _loading:
    _cancel_requested = true
    await get_tree().process_frame

  _start_loading(path, params)

## Перезагрузка текущего
func reload_level(params: Dictionary = {}) -> void:
  if _current_level_path == "":
    push_warning("LevelManager.reload_level: нет активного уровня")
    return
  load_level(_current_level_path, params)

## Выгрузить уровень
func unload_level() -> void:
  if is_instance_valid(_current_level):
    var prev := _current_level_path
    _current_level.queue_free()
    _current_level = null
    _current_level_path = ""
    emit_signal("level_unloaded", prev)

# --- Основная логика загрузки ---

func _start_loading(path: String, params: Dictionary) -> void:
  _reset_progress()
  _pending_path = path
  _pending_params = params
  _loading = true
  _cancel_requested = false
  _last_status = &"prepare"

  # смена глобального состояния (если автолоад есть)
  if typeof(GameState) != TYPE_NIL:
    GameState.game_state = GameState.GameStates.LOADING

  # показать загрузчик
  if show_loading_screen and typeof(UIManager) != TYPE_NIL:
    UIManager.show(UIManager.UIKey.LOADING_SCREEN, "base", true)

  emit_signal("level_loading_started", path)

  # подготовка — выгрузка старого
  _last_status = &"prepare"
  _p_prepare = 1.0
  if is_instance_valid(_current_level):
    var prev := _current_level_path
    _current_level.queue_free()
    _current_level = null
    _current_level_path = ""
    emit_signal("level_unloaded", prev)

  # запрос на потоковую загрузку
  _last_status = &"request"
  _p_request = 0.0
  var ok := ResourceLoader.load_threaded_request(path, "PackedScene")
  if ok != OK:
    _fail(path, "load_threaded_request failed: %s" % str(ok))
    return
  _p_request = 1.0

  # стриминг
  _last_status = &"stream"
  _p_stream = 0.0
  set_process(true)

func _process(_dt: float) -> void:
  if not _loading:
    set_process(false)
    return

  var status := ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS
  var progress_box: Array = []              # <- сюда вернётся прогресс
  if _pending_path != "":
    status = ResourceLoader.load_threaded_get_status(_pending_path, progress_box)

  var prog_val := 0.0
  if progress_box.size() > 0 and typeof(progress_box[0]) == TYPE_FLOAT:
    prog_val = float(progress_box[0])
  _p_stream = clamp(prog_val, 0.0, 1.0)

  emit_signal("level_loading_progress", _pending_path, get_progress(), _last_status)

  if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
    return

  if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
    _fail(_pending_path, "load_threaded_get_status: FAILED")
    return

  if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
    var packed := ResourceLoader.load_threaded_get(_pending_path) as PackedScene
    if packed == null:
      _fail(_pending_path, "load_threaded_get returned null")
      return

    if _cancel_requested:
      _finish_cancel(_pending_path)
      return

    _last_status = &"instantiate"
    _p_instant = 0.0
    var inst := packed.instantiate()
    _p_instant = 1.0

    if _world_root == null:
      push_error("LevelManager: WorldRoot не привязан (attach_world_root)")
      _fail(_pending_path, "WorldRoot not attached")
      return

    _world_root.add_child(inst)
    _current_level = inst
    _current_level_path = _pending_path

    _last_status = &"post"
    _p_post = 0.0

    if first_frame_warmup_ms > 0:
      await get_tree().create_timer(first_frame_warmup_ms / 1000.0).timeout

    if is_instance_valid(_current_level) and _current_level.has_method("_on_level_loaded"):
      _current_level.call("_on_level_loaded", _pending_params)

    _p_post = 1.0

    _loading = false
    _pending_path = ""
    _pending_params.clear()
    set_process(false)

    if typeof(GameState) != TYPE_NIL:
      GameState.game_state = GameState.GameStates.IN_LEVEL

    emit_signal("level_ready", _current_level_path, _current_level)

    if show_loading_screen and auto_fade_loading and typeof(UIManager) != TYPE_NIL:
      UIManager.hide(UIManager.UIKey.LOADING_SCREEN, "base", true)

# --- Помощники / ошибки / отмена ---

func _reset_progress() -> void:
  _p_prepare = 0.0
  _p_request = 0.0
  _p_stream = 0.0
  _p_instant = 0.0
  _p_post = 0.0
  _last_status = &""

func _fail(path: String, message: String) -> void:
  _loading = false
  set_process(false)
  emit_signal("level_error", path, message)
  push_error("LevelManager: %s -> %s" % [path, message])

  if typeof(GameState) != TYPE_NIL:
    GameState.game_state = GameState.GameStates.MAIN_MENU
  if show_loading_screen and typeof(UIManager) != TYPE_NIL:
    UIManager.hide(UIManager.UIKey.LOADING_SCREEN, "base", true)

func _finish_cancel(_path: String) -> void:
  _loading = false
  _cancel_requested = false
  set_process(false)
  _pending_path = ""
  _pending_params.clear()
  # загрузчик можно не гасить, если сразу начнётся новая загрузка
