extends CharacterBody3D

@export var move_speed := 5.0
@export var jump_velocity := 4.5
@export var gravity := 9.8

@export var weapon_controller: Node  # WeaponController.gd
var input_vector := Vector2.ZERO

func _ready() -> void:
  InputHandler.connect("move_input", Callable(self, "_on_move_input"))
  InputHandler.connect("jump_pressed", Callable(self, "_on_jump_pressed"))
  InputHandler.connect("interact_pressed", Callable(self, "_on_interact_pressed"))

  if weapon_controller and weapon_controller.has_method("_equip_from_data"):
    weapon_controller._equip_from_data()

func _physics_process(delta: float) -> void:
  _apply_gravity(delta)
  _move_player(delta)
  _update_pos()
  
func _update_pos() -> void:
  GameState.gun_muzzle_pos = $Geo/Muzzle.global_position

func _on_move_input(vec: Vector2) -> void:
  input_vector = vec

func _apply_gravity(delta: float) -> void:
  if not is_on_floor():
    velocity.y -= gravity * delta
  else:
    velocity.y = 0.0

func _move_player(_delta: float) -> void:
  var direction = (transform.basis.x * input_vector.x + transform.basis.z * input_vector.y).normalized()
  velocity.x = direction.x * move_speed
  velocity.z = direction.z * move_speed
  move_and_slide()

func _on_jump_pressed() -> void:
  if is_on_floor():
    velocity.y = jump_velocity

func _on_interact_pressed() -> void:
  print("Interact")
