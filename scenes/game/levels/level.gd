class_name Level extends Node2D

@export var player_one_spawner: Node2D
@export var player_two_spawner: Node2D
@export var camera: Camera2D
@export var phantom_camera: PhantomCamera2D
@export var camera_target: NodePath

const OCTOROK_COUNT := 100
const SPAWN_MARGIN := 32.0


var player_one: CharacterController
var player_two: CharacterController

func _ready() -> void:
	call_deferred("_after_ready")
	
func _after_ready():
	_spawn_players()
	call_deferred("_spawn_octoroks")

func _spawn_players():
	player_one = SpawnManager.spawn("link", player_one_spawner.global_position, self)
	player_one.controls.set_device_index(0)
	player_two = SpawnManager.spawn("link", player_two_spawner.global_position, self)
	player_two.controls.set_device_index(1)
	call_deferred("_set_camera")
	
func _set_camera():
	#await get_tree().create_timer(2.0).timeout
	var players: Array[Node2D] = [player_one, player_two]
	phantom_camera.follow_targets = players

func _spawn_octoroks() -> void:
	var view_rect := get_viewport().get_visible_rect()
	var min_pos := view_rect.position + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var max_pos := view_rect.end - Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	for i in OCTOROK_COUNT:
		var pos := Vector2(
			randf_range(min_pos.x, max_pos.x),
			randf_range(min_pos.y, max_pos.y)
		)
		SpawnManager.spawn("octorok", pos, self)
