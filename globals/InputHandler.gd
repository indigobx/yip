extends Node

# Сигналы движения
signal move_input(vector: Vector2)
signal jump_pressed
signal interact_pressed
signal night_vision_pressed

# Сигналы стрельбы
signal fire_action(pressed: bool)
signal alt_fire_action(pressed: bool)
signal toggle_fire_mode

# Сигналы камеры
signal zoom_in
signal zoom_out

var _camera: Camera3D

func _ready():
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  print_debug("InputHandler initialized")

func set_camera(camera: Camera3D):
  _camera = camera
  print_debug("Camera set: ", camera.name if camera else "null")

func _process(_delta):
  _update_movement()
  _update_cursor_state()
  _handle_time_scale()

func _unhandled_input(event):
  # Обработка мыши
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      fire_action.emit(event.pressed)
      #print_debug("Fire event: ", "PRESSED" if event.pressed else "RELEASED")
    
    if event.button_index == MOUSE_BUTTON_RIGHT:
      alt_fire_action.emit(event.pressed)
    
    if event.pressed:
      match event.button_index:
        MOUSE_BUTTON_WHEEL_UP: zoom_in.emit()
        MOUSE_BUTTON_WHEEL_DOWN: zoom_out.emit()
  
  # Обработка клавиатуры
  if event.is_action_pressed("jump"): jump_pressed.emit()
  if event.is_action_pressed("interact"): interact_pressed.emit()
  if event.is_action_pressed("night_vision"): night_vision_pressed.emit()
  if event.is_action_pressed("toggle_fire_mode"): toggle_fire_mode.emit()

func _update_movement():
  var input = Vector2(
    Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
    Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
  ).normalized()
  move_input.emit(input)

func _update_cursor_state():
  if !_camera:
    return
  
  var mouse_pos = get_viewport().get_mouse_position()
  GameState.cursor_screen_pos = mouse_pos
  
  var from = _camera.project_ray_origin(mouse_pos)
  var to = from + _camera.project_ray_normal(mouse_pos) * 1000.0
  
  var result = get_viewport().get_world_3d().direct_space_state.intersect_ray(
    PhysicsRayQueryParameters3D.create(from, to)
  )
  
  GameState.cursor_world_pos = result.position if result else to
  GameState.focus_point = GameState.cursor_world_pos


func _handle_time_scale():
  if Input.is_action_pressed("ts_default"):
    Engine.time_scale = 1.0
  elif Input.is_action_pressed("ts_stop"):
    Engine.time_scale = 0.0
  elif Input.is_action_pressed("ts_plus"):
    Engine.time_scale = min(Engine.time_scale + 0.01, 2.0)
  elif Input.is_action_pressed("ts_minus"):
    Engine.time_scale = max(Engine.time_scale - 0.01, 0.0)
