extends Node3D

const LEVEL_PATH := "res://scenes/world/%s/level.tscn"
const PLAYER_SCENE := preload("res://scenes/player/vega.tscn")

@onready var entities: Node3D = $Entities
@onready var ui: CanvasLayer = $UI
@onready var camera_controller = get_node("../Managers/CameraController")

var current_level: Node3D = null
var player: Node3D = null
var hud: Control = null


func _ready() -> void:
  load_level("00_test_range")


func load_level(level_name: String) -> void:
  var path := LEVEL_PATH % level_name
  var level_scene = load(path)

  if not level_scene:
    push_error("Level not found: %s" % path)
    return

  # Очистить предыдущий уровень
  if current_level:
    current_level.queue_free()

  current_level = level_scene.instantiate()
  add_child(current_level)
  current_level.owner = self

  # Найдём маркер спавна игрока
  var spawn = current_level.get_node_or_null("Markers/PlayerSpawn")
  var spawn_pos = spawn.global_position if spawn else Vector3.ZERO

  spawn_player(spawn_pos)
  camera_controller.set_target(player)

func spawn_player(pos: Vector3) -> void:
  if player:
    player.queue_free()

  player = PLAYER_SCENE.instantiate()
  entities.add_child(player)
  player.global_position = pos
  
