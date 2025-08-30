extends Node
## UIManager.gd — диспетчер сцен интерфейса (autoload).
## Ответственность:
## - хранит реестр UI-сцен (ключ -> путь)
## - лениво подгружает PackedScene и кэширует
## - показывает/скрывает UI в слоях: base / overlay / modal
## - корректирует смещение UIRoot с учётом видимой области (letterbox/pillarbox)
## - даёт внешний API для управления экраном загрузки (LoadingScreen)
## Зависимости:
## - main.gd должен вызвать UIManager.attach_root(UIRoot: CanvasLayer)
## - LoadingScreen.gd должен объявлять `class_name LoadingScreen`

# ---------------------------------------
# Ключи UI (можно заменить на свой enum)
# ---------------------------------------
enum UIKey {
  MAIN_MENU,
  LOADING_SCREEN
}

# ---------------------------------------
# Настройки смещения
# ---------------------------------------
@export var use_letterbox_offset: bool = true     # учитывать видимую область
@export var safe_padding: Vector2 = Vector2(0, 0) # дополнительные отступы, px

# ---------------------------------------
# Реестр: ключ -> путь к сцене
# ---------------------------------------
var _registry: Dictionary = {
  UIKey.MAIN_MENU:       "res://scenes/ui/main_menu.tscn",
  UIKey.LOADING_SCREEN:  "res://scenes/ui/loading_screen.tscn",
}

# Кэш загруженных PackedScene (ключ -> PackedScene)
var _cache: Dictionary = {} as Dictionary

# Активные инстансы по слоям: слой -> (ключ -> Control)
var _active_by_layer: Dictionary = {
  "base": {} as Dictionary,
  "overlay": {} as Dictionary,
  "modal": {} as Dictionary,
}

# Контейнеры слоёв: слой -> Control (подвешены к CanvasLayer)
var _layers: Dictionary = {} as Dictionary

# Корневой UI-слой
var _ui_root: CanvasLayer

# Ссылка на экран загрузки (если показан)
var _loading_screen: LoadingScreen

# Сигналы
signal ui_shown(ui_key: int, layer: StringName, node: Control)
signal ui_hidden(ui_key: int, layer: StringName)

# ---------------------------------------
# Публичный API
# ---------------------------------------

func attach_root(root: CanvasLayer) -> void:
  _ui_root = root
  _ensure_layers()
  _update_ui_offset()
  var win := get_window()
  if win and not win.size_changed.is_connected(_on_window_size_changed):
    win.size_changed.connect(_on_window_size_changed)
  var vp := get_viewport()
  if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
    vp.size_changed.connect(_on_viewport_size_changed)

func register(ui_key: int, scene_path: String) -> void:
  _registry[ui_key] = scene_path

func unregister(ui_key: int) -> void:
  _registry.erase(ui_key)
  _cache.erase(ui_key)
  for layer_name in _active_by_layer.keys():
    var layer_actives: Dictionary = _active_by_layer[layer_name]
    if layer_actives.has(ui_key):
      hide(ui_key, layer_name)

## Показать UI по ключу.
## layer: "base" | "overlay" | "modal"
## exclusive: если true — прячем прочие экраны на этом слое
## with_fade: простая анимация появления
func show(ui_key: int, layer: String = "base", exclusive: bool = true, with_fade: bool = true) -> Control:
  assert(_ui_root != null, "UIManager.attach_root() не вызван")
  assert(_layers.has(layer), "Неизвестный слой UI: %s" % layer)

  if exclusive:
    hide_all(layer)

  var node := _ensure_instance(ui_key)
  if node == null:
    push_error("UIManager.show: не удалось инстанцировать ui_key=%s" % str(ui_key))
    return null

  var layer_container := _layers[layer] as Control
  layer_container.add_child(node)
  var layer_actives: Dictionary = _active_by_layer[layer]
  layer_actives[ui_key] = node

  if with_fade:
    _fade_in(node)

  # если показали лоадер — сохраним ссылку
  if ui_key == UIKey.LOADING_SCREEN:
    _loading_screen = node as LoadingScreen

  emit_signal("ui_shown", ui_key, layer, node)
  return node

## Скрыть конкретный UI по ключу на слое
func hide(ui_key: int, layer: String = "base", with_fade: bool = true) -> void:
  if not _active_by_layer.has(layer):
    return

  var layer_actives: Dictionary = _active_by_layer[layer]
  if not layer_actives.has(ui_key):
    return

  var instance_ref := layer_actives[ui_key] as Control
  layer_actives.erase(ui_key)

  if with_fade and instance_ref:
    await _fade_out(instance_ref)

  if is_instance_valid(instance_ref):
    instance_ref.queue_free()

  if ui_key == UIKey.LOADING_SCREEN:
    _loading_screen = null

  emit_signal("ui_hidden", ui_key, layer)

## Скрыть все UI на указанном слое
func hide_all(layer: String = "base", with_fade: bool = false) -> void:
  if not _active_by_layer.has(layer):
    return
  var layer_actives: Dictionary = _active_by_layer[layer]
  var active_keys: Array = layer_actives.keys()
  for ui_key in active_keys:
    hide(ui_key, layer, with_fade)

## Тоггл: показать, если нет; иначе скрыть
func toggle(ui_key: int, layer: String = "overlay") -> void:
  if _active_by_layer.has(layer) and (_active_by_layer[layer] as Dictionary).has(ui_key):
    hide(ui_key, layer)
  else:
    show(ui_key, layer, false)

## Предзагрузка нескольких UI сцен
func preload_ui(ui_keys: Array) -> void:
  for k in ui_keys:
    _ensure_packed(int(k))

# ---------------------------------------
# УПРАВЛЕНИЕ ЭКРАНОМ ЗАГРУЗКИ (виджетом)
# ---------------------------------------

func show_loading_screen() -> LoadingScreen:
  var node := show(UIKey.LOADING_SCREEN, "base", true, true)
  _loading_screen = node as LoadingScreen
  if is_instance_valid(_loading_screen):
    _loading_screen.reset()
  return _loading_screen

func hide_loading_screen() -> void:
  hide(UIKey.LOADING_SCREEN, "base", true)

func set_loading_progress(p01: float) -> void:
  if is_instance_valid(_loading_screen):
    _loading_screen.set_progress01(clamp(p01, 0.0, 1.0))

func set_loading_status(text: String) -> void:
  if is_instance_valid(_loading_screen):
    _loading_screen.set_status(text)

func add_loading_log(text: String) -> void:
  if is_instance_valid(_loading_screen):
    _loading_screen.add_log(text)

# ---------------------------------------
# Внутреннее
# ---------------------------------------

func _ensure_layers() -> void:
  _layers.clear()
  for name_str in ["base", "overlay", "modal"]:
    var layer_container := Control.new()
    layer_container.name = name_str.capitalize()
    layer_container.mouse_filter = Control.MOUSE_FILTER_PASS
    layer_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layer_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layer_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    _ui_root.add_child(layer_container)
    _layers[name_str] = layer_container
    if not _active_by_layer.has(name_str):
      _active_by_layer[name_str] = {} as Dictionary

func _ensure_packed(ui_key: int) -> PackedScene:
  if _cache.has(ui_key):
    return _cache[ui_key] as PackedScene
  if not _registry.has(ui_key):
    push_error("UIManager: ключ не зарегистрирован: %s" % str(ui_key))
    return null
  var packed := load(_registry[ui_key]) as PackedScene
  if packed != null:
    _cache[ui_key] = packed
  return packed

func _ensure_instance(ui_key: int) -> Control:
  var packed := _ensure_packed(ui_key)
  if packed == null:
    return null
  var node := packed.instantiate()
  return node as Control

# ---------------------------------------
# Смещение CanvasLayer под реальную видимую область
# ---------------------------------------

func _update_ui_offset() -> void:
  if not use_letterbox_offset or _ui_root == null:
    return
  var rect := get_viewport().get_visible_rect()
  var base_off := rect.position
  var final_off := base_off + safe_padding
  _ui_root.offset = final_off.floor()

func _on_window_size_changed() -> void:
  _update_ui_offset()

func _on_viewport_size_changed() -> void:
  _update_ui_offset()

# ---------------------------------------
# Простые фейды
# ---------------------------------------

func _fade_in(ci: CanvasItem, duration: float = 0.14) -> void:
  if ci == null:
    return
  ci.modulate.a = 0.0
  var tw := create_tween()
  tw.tween_property(ci, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _fade_out(ci: CanvasItem, duration: float = 0.12) -> void:
  if ci == null:
    return
  var tw := create_tween()
  tw.tween_property(ci, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
  await tw.finished
