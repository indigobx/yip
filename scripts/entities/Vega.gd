extends CharacterBody3D

@export var move_speed := 6.0
@export var jump_velocity := 4.5
@export var gravity := 9.8

@export var weapon_controller: Node  # WeaponController.gd
var input_vector := Vector2.ZERO
var state := "idle"

var _current_anim: String = ""

func _ready() -> void:
  InputHandler.connect("move_input", Callable(self, "_on_move_input"))
  InputHandler.connect("jump_pressed", Callable(self, "_on_jump_pressed"))
  InputHandler.connect("interact_pressed", Callable(self, "_on_interact_pressed"))

  if weapon_controller and weapon_controller.has_method("_equip_from_data"):
    weapon_controller._equip_from_data()

func _physics_process(delta: float) -> void:
  _apply_gravity(delta)
  _cast_shadow()
  _move_player(delta)
  _rotate_to_cursor()
  _update_pos()
  _update_animation()

func _rotate_to_cursor() -> void:
  var from = global_transform.origin
  var to = GameState.cursor_world_pos

  var direction = to - from
  direction.y = 0  # Убираем вертикальный компонент

  if direction.length_squared() < 0.01:
    return

  var angle = atan2(direction.x, direction.z) + PI
  $Geo.rotation.y = angle
  $Discrete.rotation_degrees.y = angle_to_8dir(rad_to_deg(angle)) * 45

func _update_pos() -> void:
  GameState.gun_muzzle_pos = $Discrete/Muzzle.global_position

func _on_move_input(vec: Vector2) -> void:
  input_vector = vec

func _apply_gravity(delta: float) -> void:
  if not is_on_floor():
    velocity.y -= gravity * delta
  #else:
    #velocity.y = 0.0

func _cast_shadow() -> void:
  pass

func _move_player(_delta: float) -> void:
  var direction = (transform.basis.x * input_vector.x + transform.basis.z * input_vector.y).normalized()
  velocity.x = direction.x * move_speed
  velocity.z = direction.z * move_speed
  move_and_slide()

func _on_jump_pressed() -> void:
  print("jump")
  if is_on_floor():
    print("jumping")
    velocity.y = jump_velocity

func _on_interact_pressed() -> void:
  print("Interact")

func _update_animation() -> void:
  state = "walk" if input_vector.length_squared() > 0.01 else "idle"
  var dir = angle_to_8dir($Geo.rotation_degrees.y)
  play_animation(state, dir)

func angle_to_8dir(angle_deg: float) -> int:
  var normalized := fposmod(angle_deg, 360.0)
  var sector := int(round(normalized / 45.0)) % 8
  return sector

func play_animation(state: String, direction: int) -> void:
  direction = clamp(direction, 0, 7)
  var stage = clamp(PlayerData.pregnancy_stage, 0, 5)
  var anim_name := "%s_%d_%d" % [state, direction, stage]

  if anim_name == _current_anim:
    return  # уже проигрывается, не перезапускать

  if $AnimatedSprite3D.sprite_frames.has_animation(anim_name):
    $AnimatedSprite3D.play(anim_name)
    _current_anim = anim_name
  else:
    push_warning("Animation not found: %s" % anim_name)
