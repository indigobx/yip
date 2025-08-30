extends Control
class_name LoadingScreen

@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var progress_label: Label = $MarginContainer/VBoxContainer/Label
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar

# внутренние поля
var _progress: float = 0.0
var _status_text: String = ""

# экспортируемое свойство прогресса 0..1
@export var progress: float:
  get:
    return _progress
  set(value):
    _progress = clamp(value, 0.0, 1.0)
    _apply_progress()

# экспортируемое свойство статуса
@export var status_text: String:
  get:
    return _status_text
  set(value):
    _status_text = value
    _apply_progress()

# ------------------------
# Публичные методы
# ------------------------

func set_progress01(value01: float) -> void:
  progress = value01

func set_status(text: String) -> void:
  status_text = text

func set_progress_and_status(value01: float, text: String) -> void:
  _progress = clamp(value01, 0.0, 1.0)
  _status_text = text
  _apply_progress()

func add_log(text: String) -> void:
  var lines: PackedStringArray = text.split("\n")
  for line in lines:
    log_label.append_text(line + "\n")
  # автоскролл вниз
  log_label.scroll_to_line(max(0, log_label.get_line_count() - 1))

func clear_log() -> void:
  log_label.clear()

func reset() -> void:
  clear_log()
  progress = 0.0
  status_text = ""

# ------------------------
# Внутреннее
# ------------------------

func _apply_progress() -> void:
  if progress_bar:
    progress_bar.value = _progress * 100.0  # ProgressBar работает в 0..100
  if progress_label:
    if _status_text != "":
      progress_label.text = "%s (%.0f%%)" % [_status_text, _progress * 100.0]
    else:
      progress_label.text = "%.0f%%" % (_progress * 100.0)
