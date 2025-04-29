extends Node

signal move_input(vector2)
signal jump_pressed
signal fire_pressed
signal fire_released
signal fire_single
signal fire_charge
signal interact_pressed
signal zoom_in
signal zoom_out
signal cursor_updated(screen_pos: Vector2, world_pos: Vector3)

var _fire_time_pressed := 0
const CLICK_THRESHOLD_MS := 200

var _movement_vector := Vector2.ZERO
var _camera: Camera3D = null

#@onready var debug_cursor := MeshInstance3D.new()
@onready var cursor_scene = preload("res://scenes/misc/cursor.tscn")
var cursor


func set_camera(camera: Camera3D) -> void:
  _camera = camera

func _ready() -> void:
  cursor = cursor_scene.instantiate()
  add_child(cursor)


func _process(_delta: float) -> void:
  _update_movement()
  _update_cursor()

func _update_movement() -> void:
  var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
  var y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
  var new_vector = Vector2(x, y).normalized()

  if new_vector != _movement_vector:
    _movement_vector = new_vector
    emit_signal("move_input", _movement_vector)

func _update_cursor() -> void:
  if not _camera:
    return

  GameState.cursor_screen_pos = get_viewport().get_mouse_position()

  var from = _camera.project_ray_origin(GameState.cursor_screen_pos)
  var to = from + _camera.project_ray_normal(GameState.cursor_screen_pos) * 1000.0

  var space_state = get_viewport().get_world_3d().direct_space_state
  var query := PhysicsRayQueryParameters3D.create(from, to)
  var result = space_state.intersect_ray(query)

  GameState.cursor_world_pos = result.position if result else to
  cursor.global_position = GameState.cursor_world_pos
  emit_signal("cursor_updated", GameState.cursor_screen_pos, GameState.cursor_world_pos)

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("jump"):
    emit_signal("jump_pressed")

  if event.is_action_pressed("interact"):
    emit_signal("interact_pressed")

  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    if event.pressed:
      _fire_time_pressed = Time.get_ticks_msec()
      emit_signal("fire_pressed")
    else:
      var duration = Time.get_ticks_msec() - _fire_time_pressed
      emit_signal("fire_released")

      if duration < CLICK_THRESHOLD_MS:
        emit_signal("fire_single")
      else:
        emit_signal("fire_charge")

  if event is InputEventMouseButton and event.pressed:
    match event.button_index:
      MOUSE_BUTTON_WHEEL_UP:
        emit_signal("zoom_in")
      MOUSE_BUTTON_WHEEL_DOWN:
        emit_signal("zoom_out")
    
