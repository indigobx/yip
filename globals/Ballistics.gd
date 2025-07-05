extends Node

# Обновление снаряда — один physics_step
func update_projectile(projectile: Node3D, delta: float) -> void:
  var ammo: AmmoData = projectile.ammo
  var velocity: Vector3 = projectile.velocity
  var env: Dictionary = GameState.env_conditions

  var mass: float = ammo.mass * 0.001  # г → кг
  var radius: float = ammo.caliber * 0.001 * 0.5  # мм → м
  var cross_section: float = PI * radius * radius

  var rho: float = get_air_density(env["pressure"], env["temperature"], env["atmosphere"])
  var drag: float = 0.5 * ammo.drag_coef * rho * cross_section * velocity.length_squared()
  var drag_force: Vector3 = -velocity.normalized() * drag
  var acceleration: Vector3 = drag_force / mass

  # Гравитация
  acceleration.y -= env["gravity"]

  # Тяга
  if ammo.has_thruster and projectile.burn_time < ammo.burn_time:
    var thrust_force: float = ammo.thrust_force
    var thrust_accel: Vector3 = projectile.global_transform.basis.z.normalized() * thrust_force / mass
    acceleration += thrust_accel

    var burn_rate: float = ammo.fuel_mass / ammo.burn_time  # г/с
    projectile.burn_time += delta
    mass -= burn_rate * delta * 0.001  # г → кг

  # Ветер
  var wind: Vector3 = env["wind_direction"].normalized() * env["wind_strength"]
  var wind_effect: Vector3 = (wind - velocity) * 0.05
  acceleration += wind_effect

  # Обновление скорости и позиции
  velocity += acceleration * delta
  projectile.velocity = velocity
  projectile.global_position += velocity * delta

  # Ориентируем по траектории
  if velocity.length() > 0.01:
    projectile.look_at(projectile.global_position + velocity, Vector3.UP)

# Расчёт точки попадания с учётом среды
func get_hit_point(origin: Vector3, direction: Vector3, ammo: AmmoData, max_distance: float = 1000.0) -> Dictionary:
  var velocity: Vector3 = direction.normalized() * ammo.speed
  var position: Vector3 = origin

  var env: Dictionary = GameState.env_conditions
  var mass: float = ammo.mass * 0.001
  var radius: float = ammo.caliber * 0.001 * 0.5
  var cross_section: float = PI * radius * radius
  var rho: float = get_air_density(env["pressure"], env["temperature"], env["atmosphere"])

  var space_state: PhysicsDirectSpaceState3D = GameState.get_world_3d().direct_space_state

  var distance_traveled: float = 0.0
  var step: float = 0.1  # м (частота трассировки)

  while distance_traveled < max_distance:
    # Расчёт drag + gravity + ветер
    var drag: float = 0.5 * ammo.drag_coef * rho * cross_section * velocity.length_squared()
    var drag_force: Vector3 = -velocity.normalized() * drag
    var acceleration: Vector3 = drag_force / mass
    acceleration.y -= env["gravity"]
    var wind: Vector3 = env["wind_direction"].normalized() * env["wind_strength"]
    var wind_effect: Vector3 = (wind - velocity) * 0.05
    acceleration += wind_effect

    velocity += acceleration * step
    var next_pos: Vector3 = position + velocity.normalized() * step

    # Raycast до следующей точки
    var query := PhysicsRayQueryParameters3D.create(position, next_pos)
    var result: Dictionary = space_state.intersect_ray(query)

    if result.size() > 0:
      return {
        "hit": true,
        "position": result["position"],
        "normal": result["normal"],
        "collider": result["collider"]
      }

    position = next_pos
    distance_traveled += step

  return {
    "hit": false,
    "position": position
  }

# Плотность воздуха (зависит от атмосферы)
func get_air_density(pressure: float, temperature: float, atmosphere: String) -> float:
  var R: float = 8.314
  var M: float = 0.029

  match atmosphere:
    "clean_air", "urban_air":
      M = 0.029
    "oxygen":
      M = 0.032
    "co2":
      M = 0.044
    "methane":
      M = 0.016
    "helium":
      M = 0.004
    "argon":
      M = 0.040
    "underwater":
      return 997.0
    _:
      M = 0.029

  var T: float = temperature + 273.15
  var P: float = pressure * 101325.0
  return (P * M) / (R * T)

func get_aim_direction(from: Vector3, to: Vector3, ammo: AmmoData) -> Vector3:
  var g: float = GameState.env_conditions.get("gravity", 9.81)
  var v0: float = ammo.speed
  if v0 <= 0.0:
    push_warning("Ammo speed is zero or negative.")
    return (to - from).normalized()

  var flat_distance: float = (to - from).length()
  var flight_time: float = flat_distance / v0
  var drop: float = 0.5 * g * flight_time * flight_time

  var corrected_to: Vector3 = to + Vector3.UP * drop
  return (corrected_to - from).normalized()
