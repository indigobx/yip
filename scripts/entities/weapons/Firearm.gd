extends Node3D
class_name Firearm

# Режимы стрельбы
enum FireMode {SAFE, SINGLE, BURST, AUTO}
var current_mode: FireMode = FireMode.SINGLE
var available_modes: Array[FireMode] = []

# Ссылки
var projectile = preload("res://scenes/weapons/Projectile.tscn")
var weapon: WeaponData
var ammo: AmmoData

# Состояние
var is_trigger_pressed := false
var fire_timer := 0.0
var burst_counter := 0
var is_firing := false

func _ready() -> void:
  # Инициализация оружия
  weapon = WeaponRegistry.get_weapon_by_name(PlayerData.selected_weapon_name)
  ammo = AmmoRegistry.get_ammo_by_name(weapon.ammo_type)
  
  # Определение доступных режимов
  _update_available_modes()
  
  # Подключение сигналов
  InputHandler.fire_action.connect(_on_fire_action)
  InputHandler.toggle_fire_mode.connect(_toggle_fire_mode)
  
  print("Firearm initialized. Mode: ", FireMode.keys()[current_mode])

func _process(delta):
  if fire_timer > 0:
    fire_timer -= delta
  _aim()
  _handle_firing(delta)

func _aim() -> void:
  look_at(GameState.cursor_world_pos)

func _handle_firing(_delta: float):
  if !is_trigger_pressed or current_mode == FireMode.SAFE:
    return
  
  match current_mode:
    FireMode.AUTO:
      if _can_fire():
        _fire()
        fire_timer = _get_fire_delay(weapon.fire_rate_auto)
    
    FireMode.BURST:
      if burst_counter > 0 and _can_fire():
        _fire()
        burst_counter -= 1
        fire_timer = _get_fire_delay(weapon.fire_rate_burst)
        
        if burst_counter <= 0:
          is_trigger_pressed = false

func _on_fire_action(pressed: bool):
  #print("Fire action: ", "PRESSED" if pressed else "RELEASED")
  is_trigger_pressed = pressed
  
  if !pressed:
    return
  
  if current_mode == FireMode.SAFE:
    print("Weapon is on SAFE")
    return
  
  match current_mode:
    FireMode.SINGLE:
      if _can_fire():
        _fire()
        fire_timer = _get_fire_delay(weapon.fire_rate_single)
    
    FireMode.BURST:
      burst_counter = weapon.burst_rounds if weapon.burst_rounds > 0 else 3
      fire_timer = 0  # Сбрасываем таймер для немедленного выстрела

func _toggle_fire_mode():
  if available_modes.size() <= 1:
    return
  
  var current_index = available_modes.find(current_mode)
  var next_index = (current_index + 1) % available_modes.size()
  current_mode = available_modes[next_index]
  
  print("Fire mode changed to: ", FireMode.keys()[current_mode])
  burst_counter = 0
  is_trigger_pressed = false

func _update_available_modes():
  available_modes = []
  
  # Всегда добавляем SAFE если есть предохранитель
  if weapon.has_safety: 
    available_modes.append(FireMode.SAFE)
  
  # Добавляем доступные режимы стрельбы
  if weapon.fire_rate_single > 0: 
    available_modes.append(FireMode.SINGLE)
  if weapon.fire_rate_burst > 0 and weapon.burst_rounds > 0: 
    available_modes.append(FireMode.BURST)
  if weapon.fire_rate_auto > 0: 
    available_modes.append(FireMode.AUTO)
  
  # Если нет доступных режимов (кроме SAFE), добавляем SINGLE как fallback
  if available_modes.size() == (1 if weapon.has_safety else 0):
    available_modes.append(FireMode.SINGLE)
  
  # Устанавливаем первый доступный режим
  if available_modes.size() > 0 and !available_modes.has(current_mode):
    current_mode = available_modes[0]

func _can_fire() -> bool:
  return fire_timer <= 0 and !is_zero_approx(weapon.fire_rate_single)

func _get_fire_delay(rpm: float) -> float:
  return 60.0 / rpm if rpm > 0 else 0.1

func _fire():
  # Проверяем, что ammo существует
  if not ammo:
    push_error("No ammo assigned to firearm!")
    return

  var proj = projectile.instantiate()
  
  # Создаем КОПИЮ данных боеприпаса
  proj.ammo = ammo.duplicate(true)  # true для глубокого копирования
  
  # Получаем ноду Projectiles безопасно
  var projectiles_node = get_tree().root.get_node_or_null("Main/Game/Projectiles")
  if projectiles_node:
    projectiles_node.add_child(proj)
    proj.global_position = global_position
    proj.set_initial_direction(-global_transform.basis.z)
    
    # DEBUG: Проверяем, что ammo инициализирован корректно
    if not proj.ammo or not proj.ammo.get("speed"):
      push_error("Projectile created with invalid ammo data!")
  else:
    push_error("Projectiles node not found!")
