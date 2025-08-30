extends Control
class_name GameConsole
## Autoload консоль (оверлей), без .tscn
## Toggle: InputMap action "toggle_console" (обычно `~`)
## Ввод: Enter (submit), Shift+Enter (новая строка), ↑/↓ (история)
## Логи: Console.log(text: String, severity := Severity.INFO, no_newline := false)
##
## Важно:
## - По умолчанию скрыта, игру НЕ останавливает.
## - Не блокирует ввод; специально НЕ перехватывает нажатие тильды/бектика (toggle),
##   чтобы это нажатие могло долететь до игры, если нужно.

# ---------- Настройки ----------
@export var show_timestamp: bool = true
@export var prompt_on_open: bool = true
@export var timestamp_format: String = "HH:mm:ss"
@export var prompt: String = "> "
@export var max_history: int = 200
@export var input_height: int = 26  # px

# Палитра (BBCode цвета)
@export var color_info: Color   = Color("#d5d0db")
@export var color_warn: Color   = Color("#ffd85e")
@export var color_error: Color  = Color("#ff546b")
@export var color_debug: Color  = Color("#0ce6f2")
@export var color_prompt: Color = Color("#94d9a5")

# Уровни важности
enum Severity { INFO, WARN, ERROR, DEBUG }

# ---------- Узлы (создаются кодом) ----------
var _root_margin: MarginContainer
var _root_vbox: VBoxContainer
var _scroll: ScrollContainer
var _log_view: RichTextLabel
var _input: CodeEdit

# ---------- Состояние ----------
var _commands: Dictionary = {}      # cmd_name(String)->Callable(Array->Variant)
var _aliases:  Dictionary = {}      # alias(String)->cmd_name(String)
var _history:  Array = []           # Array[String]
var _hist_idx: int = -1
var _partial_no_newline: bool = false  # висит незакрытая строка

# ---------- Жизненный цикл ----------
func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS
  mouse_filter = Control.MOUSE_FILTER_PASS   # не блокировать клики по миру
  z_index = 100
  _build_ui()
  # занять всю видимую область сразу
  _fit_to_visible_rect()

  # подписки на ресайз
  var win := get_window()
  if win and not win.size_changed.is_connected(Callable(self, "_on_window_or_viewport_resize")):
    win.size_changed.connect(Callable(self, "_on_window_or_viewport_resize"))
  var vp := get_viewport()
  if vp and not vp.size_changed.is_connected(Callable(self, "_on_window_or_viewport_resize")):
    vp.size_changed.connect(Callable(self, "_on_window_or_viewport_resize"))
  visible = false   # по умолчанию скрыта

  _input.focus_mode = Control.FOCUS_ALL
  if not _input.gui_input.is_connected(Callable(self, "_on_input_gui")):
    _input.gui_input.connect(Callable(self, "_on_input_gui"))

  _register_builtin_commands()

  if prompt_on_open:
    _append_prompt()

  self.log("Console ready. Type 'help'.", Severity.INFO, false)

func _fit_to_visible_rect() -> void:
  var r: Rect2 = get_viewport().get_visible_rect()  # учтёт offset при letterbox
  position = r.position
  size = r.size

func _on_window_or_viewport_resize() -> void:
  _fit_to_visible_rect()

func _unhandled_input(e: InputEvent) -> void:
  # НЕ вызываем accept_event() на toggle — чтобы `~`/``
  # не блокировался и мог долететь до игры при необходимости.
  if e.is_action_pressed("toggle_console"):
    toggle()
    return
  if visible and e.is_action_pressed("ui_cancel"):
    hide_console()
    # Esc тоже не гасим глобально

# ---------- Построение UI ----------
func _build_ui() -> void:
  set_anchors_preset(Control.PRESET_FULL_RECT)
  size_flags_horizontal = Control.SIZE_EXPAND_FILL
  size_flags_vertical = Control.SIZE_EXPAND_FILL

  _root_margin = MarginContainer.new()
  _root_margin.name = "MarginContainer"
  _root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
  _root_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _root_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
  _root_margin.add_theme_constant_override("margin_left", 8)
  _root_margin.add_theme_constant_override("margin_top", 8)
  _root_margin.add_theme_constant_override("margin_right", 8)
  _root_margin.add_theme_constant_override("margin_bottom", 8)
  add_child(_root_margin)

  _root_vbox = VBoxContainer.new()
  _root_vbox.name = "VBoxContainer"
  _root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
  _root_margin.add_child(_root_vbox)

  _scroll = ScrollContainer.new()
  _scroll.name = "ScrollContainer"
  _scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
  _root_vbox.add_child(_scroll)

  _log_view = RichTextLabel.new()
  _log_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _log_view.name = "ConsoleLog"
  _log_view.bbcode_enabled = true
  _log_view.fit_content = true
  _log_view.selection_enabled = true
  _log_view.scroll_active = true
  _scroll.add_child(_log_view)

  _input = CodeEdit.new()
  _input.name = "ConsoleInput"
  _input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _input.size_flags_vertical = Control.SIZE_EXPAND_FILL
  _input.size_flags_stretch_ratio = 0.1
  _input.custom_minimum_size = Vector2(0, input_height)
  _input.wrap_mode = CodeEdit.LINE_WRAPPING_NONE
  #_input.show_line_numbers = false        # спрячем гуттер с номерами строк
  _input.syntax_highlighter = null
  _root_vbox.add_child(_input)

# ---------- Публичный API ----------
func show_console() -> void:
  visible = true
  set_process_input(true)
  _input.grab_focus()
  var cur_line := _input.get_caret_line()
  var line_len := _input.get_line(cur_line).length()
  _input.set_caret_column(line_len, true)
  if prompt_on_open and not _partial_no_newline:
    _append_prompt()

func hide_console() -> void:
  visible = false
  set_process_input(false)
  if has_focus():
    release_focus()

func toggle() -> void:
  if visible: hide_console()
  else: show_console()

# severity: Console.Severity (0..3) или int
func log(text: String, severity := Severity.INFO, no_newline := false) -> void:
  var lvl: int = int(severity)
  _append_line(text, lvl, no_newline)

func register_command(cmd_name: String, fn: Callable) -> void:
  _commands[cmd_name.to_lower()] = fn

func unregister_command(cmd_name: String) -> void:
  _commands.erase(cmd_name.to_lower())

func register_alias(alias_name: String, real_cmd_name: String) -> void:
  _aliases[alias_name.to_lower()] = real_cmd_name.to_lower()

func execute(line: String) -> void:
  _exec_command(line)

# ---------- Ввод в CodeEdit ----------
func _on_input_gui(event: InputEvent) -> void:
  if not (event is InputEventKey):
    return
  var e := event as InputEventKey
  if not e.pressed or e.echo:
    return

  match e.keycode:
    KEY_ENTER, KEY_KP_ENTER:
      if e.shift_pressed:
        return # разрешаем перенос строки
      # только Enter перехватываем полностью
      get_viewport().set_input_as_handled()
      accept_event()
      var line := _input.text.strip_edges()
      _input.text = ""
      _submit_command(line)
      return

    KEY_UP:
      if _history.is_empty():
        return
      # стрелки истории перехватываем локально
      accept_event()
      _hist_idx = clamp(_hist_idx - 1, -1, _history.size() - 1)
      _input.text = "" if _hist_idx == -1 else str(_history[_hist_idx])
      var cur_line := _input.get_caret_line()
      var line_len := _input.get_line(cur_line).length()
      _input.set_caret_column(line_len, true)
      return

    KEY_DOWN:
      if _history.is_empty():
        return
      accept_event()
      _hist_idx = clamp(_hist_idx + 1, -1, _history.size() - 1)
      _input.text = "" if _hist_idx == -1 else str(_history[_hist_idx])
      var cur_line := _input.get_caret_line()
      var line_len := _input.get_line(cur_line).length()
      _input.set_caret_column(line_len, true)
      return

  # все прочие клавиши НЕ перехватываем → не блокируем игру

func _submit_command(line: String) -> void:
  if line.is_empty():
    if not _partial_no_newline:
      _append_prompt()
    return
  _push_history(line)
  _append_echo(line)
  _exec_command(line)
  if not _partial_no_newline:
    _append_prompt()

# ---------- Команды ----------
func _exec_command(line: String) -> void:
  var parts: PackedStringArray = line.split(" ", false, 0)
  if parts.is_empty():
    return

  var cmd_name := parts[0].to_lower()
  if _aliases.has(cmd_name):
    cmd_name = str(_aliases[cmd_name])

  var args: Array = []
  for i in range(1, parts.size()):
    args.append(parts[i])

  if _commands.has(cmd_name):
    var cb := _commands[cmd_name] as Callable
    var result = cb.call(args)  # команды принимают Array аргументов
    if result != null and str(result) != "":
      _append_line(str(result), Severity.INFO, false)
  else:
    _append_line("[error] Unknown command: " + cmd_name, Severity.ERROR, false)

func _register_builtin_commands() -> void:
  register_command("help", Callable(self, "_cmd_help"))
  register_command("clear", Callable(self, "_cmd_clear"))
  register_command("echo",  Callable(self, "_cmd_echo"))
  register_command("warn",  Callable(self, "_cmd_warn"))
  register_command("error", Callable(self, "_cmd_error"))
  register_command("debug", Callable(self, "_cmd_debug"))

func _cmd_help(_args: Array) -> String:
  var names := _commands.keys()
  names.sort()
  return "Commands: " + ", ".join(names)

func _cmd_clear(_args: Array) -> String:
  if _log_view:
    _log_view.clear()
  _partial_no_newline = false
  return ""

func _cmd_echo(args: Array) -> String:
  return " ".join(args)

func _cmd_warn(args: Array) -> String:
  self.log(" ".join(args), Severity.WARN, false)
  return ""

func _cmd_error(args: Array) -> String:
  self.log(" ".join(args), Severity.ERROR, false)
  return ""

func _cmd_debug(args: Array) -> String:
  self.log(" ".join(args), Severity.DEBUG, false)
  return ""

# ---------- Лог форматирование ----------
func _append_prompt() -> void:
  _append_bbcode("[color=%s]%s[/color]" % [ _color_to_bb(color_prompt), prompt ], true)
  _partial_no_newline = true

func _append_echo(line: String) -> void:
  _append_bbcode("[color=%s]%s%s[/color]" % [ _color_to_bb(color_prompt), prompt, line ], false)

func _append_line(text: String, severity: int, no_newline: bool) -> void:
  var bb_color := _color_for_level(severity)
  var stamp := ""
  if show_timestamp:
    var now := Time.get_datetime_dict_from_system()
    stamp = "%02d:%02d:%02d " % [now.hour, now.minute, now.second]
  var msg := "%s%s" % [stamp, text]
  var bb := "[color=%s]%s[/color]" % [_color_to_bb(bb_color), msg]
  _append_bbcode(bb, no_newline)

func _append_bbcode(bb: String, no_newline: bool) -> void:
  if not _log_view:
    return
  _log_view.append_text(bb)
  if not no_newline:
    _log_view.append_text("\n")
    _partial_no_newline = false
  else:
    _partial_no_newline = true
  _log_view.scroll_to_line(max(0, _log_view.get_line_count() - 1))

func _color_for_level(severity: int) -> Color:
  match severity:
    Severity.WARN:  return color_warn
    Severity.ERROR: return color_error
    Severity.DEBUG: return color_debug
    _:              return color_info

func _color_to_bb(c: Color) -> String:
  return "#%02x%02x%02x" % [ int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0) ]

# ---------- История ----------
func _push_history(line: String) -> void:
  _history.append(line)
  if _history.size() > max_history:
    _history.pop_front()
  _hist_idx = _history.size()
