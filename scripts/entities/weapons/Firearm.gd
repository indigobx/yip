extends Node3D
class_name Firearm

# Режимы стрельбы
enum FireMode {SAFE, SINGLE, BURST, AUTO}
var current_mode: FireMode = FireMode.SINGLE
var available_modes: Array[FireMode] = []

# Ссылки
var projectile = preload("res://scenes/weapons/Projectile.tscn")
@onready var weapon_base: Node3D = $WeaponBase
@onready var weapon_model: MeshInstance3D = $WeaponBase/WeaponModel
@onready var muzzle: Marker3D = $WeaponBase/Muzzle
var weapon: WeaponData
var ammo: AmmoData

# Состояние
var is_trigger_pressed := false
var fire_timer := 0.0
var burst_counter := 0
var is_firing := false
var current_spread_multiplier := 1.0
var spread_multiplier_per_shot := 1.5
var max_spread_multiplier := 0.0
var spread_multiplier_recovery := 0.5
# Настройки отдачи
var recoil_offset := Vector3.ZERO
var target_recoil_offset := Vector3.ZERO
var recoil_rotation := Vector3.ZERO
var target_recoil_rotation := Vector3.ZERO


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
  if current_spread_multiplier > 1.0:
    current_spread_multiplier = max(1.0, current_spread_multiplier - delta * spread_multiplier_recovery)
  _update_recoil(delta)


func _aim() -> void:
  # Поворот всего оружия (Weapon) для прицеливания
  look_at(GameState.cursor_world_pos, Vector3.UP)

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


func _calculate_spread_angle() -> float:
  # Учитываем множитель текущего разброса
  return deg_to_rad((weapon.spread_moa + ammo.spread_moa) / 60.0) * current_spread_multiplier


func _apply_spread(base_direction: Vector3) -> Vector3:
  var spread_angle = _calculate_spread_angle()
  
  # Используем нормальное распределение для более реалистичного разброса
  var angle_x = _gaussian_random(0, spread_angle/3.0)
  var angle_y = _gaussian_random(0, spread_angle/3.0)
  
  var spread_transform = Transform3D()
  spread_transform = spread_transform.rotated(global_transform.basis.x, angle_y)
  spread_transform = spread_transform.rotated(global_transform.basis.y, angle_x)
  
  return (spread_transform * base_direction).normalized()

func _gaussian_random(mean: float, deviation: float) -> float:
  # Генерация случайного числа с нормальным распределением
  var u1 := 1.0 - randf()
  var u2 := 1.0 - randf()
  var z0 := sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
  return z0 * deviation + mean

func _calculate_recoil_power() -> float:
  var bullet_energy = 0.5 * ammo.mass * pow(ammo.speed, 2)
  var base_power = bullet_energy * 0.0002
  var skill_level = min(PlayerData.skills["recoil_resistance"], 20)
  var skill_factor = 1.0 - pow(skill_level / 20.0, 0.4)  # Более плавное уменьшение
  return base_power * skill_factor

func _get_vertical_multiplier(skill: int) -> float:
  # 1.5 на 0 уровне, снижается до 0.1 на 20 уровне
  return clamp(1.5 - (1.4 * pow(skill / 20.0, 0.5)), 0.1, 1.5)

func _get_horizontal_multiplier(skill: int) -> float:
  # 1.3 на 0 уровне, снижается до 0.05 на 20 уровне
  return clamp(1.3 - (1.25 * pow(skill / 20.0, 0.6)), 0.05, 1.3)

func _apply_recoil():
  var power = _calculate_recoil_power()
  var skill = min(PlayerData.skills["recoil_resistance"], 20)
  
  var vertical = power * _get_vertical_multiplier(skill)
  var horizontal = power * randf_range(-0.4, 0.4) * _get_horizontal_multiplier(skill)
  
  # Исправленное направление отдачи (теперь вверх)
  target_recoil_offset += Vector3(
    clamp(horizontal, -Config.max_recoil_offset.x, Config.max_recoil_offset.x),
    clamp(vertical * 0.8, 0, Config.max_recoil_offset.y),  # Только вверх
    clamp(-vertical * 0.2, -Config.max_recoil_offset.z, 0) # Слабый отброс назад
  )
  
  target_recoil_rotation += Vector3(
    clamp(-vertical * 0.5, -Config.max_recoil_rotation.x, 0),  # Наклон назад
    clamp(horizontal * 1.2, -Config.max_recoil_rotation.y, Config.max_recoil_rotation.y),
    0
  )

func _update_recoil(delta: float):
  var recovery_speed = 3.0 + (PlayerData.skills["weapon_handling"] * 0.3)
  
  weapon_base.position = weapon_base.position.lerp(
    Vector3(0, 0, -0.652) + target_recoil_offset,
    recovery_speed * delta
  )
  
  weapon_base.rotation = weapon_base.rotation.lerp(
    -target_recoil_rotation,
    recovery_speed * delta
  )
  
  target_recoil_offset = target_recoil_offset.lerp(
    Vector3.ZERO,
    recovery_speed * delta * 0.6
  )
  
  target_recoil_rotation = target_recoil_rotation.lerp(
    Vector3.ZERO,
    recovery_speed * delta * 0.6
  )
  if GameState.game.hud:
    GameState.game.hud.recoil_bar.value = weapon_base.rotation_degrees.x

func _fire():
  if not ammo:
    push_error("No ammo assigned to firearm!")
    return

  var proj = projectile.instantiate()
  proj.ammo = ammo.duplicate(true)
  
  # Разброс
  current_spread_multiplier = min(
    current_spread_multiplier + spread_multiplier_per_shot, 
    max_spread_multiplier
  )
  
  # Выстрел из позиции muzzle с учетом его локальных координат
  var base_direction = -muzzle.global_transform.basis.z
  var spread_direction = _apply_spread(base_direction)
  
  var projectiles_node = get_tree().root.get_node_or_null("Main/Game/Projectiles")
  if projectiles_node:
    projectiles_node.add_child(proj)
    proj.global_position = muzzle.global_position
    proj.set_initial_direction(spread_direction)
  
  _apply_recoil()
  
  # Визуальные эффекты
  #if GameState.game and GameState.game.fx:
    #GameState.game.fx.add_muzzle_flash(muzzle.global_transform)
  
  # Анимация выстрела
  #if $AnimationPlayer.has_animation("fire"):
    #$AnimationPlayer.play("fire")
