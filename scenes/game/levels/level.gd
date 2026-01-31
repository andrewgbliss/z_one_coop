class_name Level extends Node2D

@export var player_one_spawner: Node2D
@export var player_two_spawner: Node2D
@export var camera: Camera2D
@export var phantom_camera: PhantomCamera2D
@export var camera_target: NodePath

var player_one: CharacterController
var player_two: CharacterController

func _ready() -> void:
	call_deferred("_after_ready")
	
func _after_ready():
	_spawn_players()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()
		if GameManager.is_paused:
			UiManager.game_menus.push("PauseMenu")
		else:
			UiManager.game_menus.pop_all()

func _spawn_players():
	player_one = SpawnManager.spawn("link", player_one_spawner.global_position, self)
	player_one.controls.set_device_index(0)
	player_two = SpawnManager.spawn("link", player_two_spawner.global_position, self)
	player_two.controls.set_device_index(1)
	call_deferred("_set_camera")
	
func _set_camera():
	var players: Array[Node2D] = [player_one, player_two]
	phantom_camera.follow_targets = players
