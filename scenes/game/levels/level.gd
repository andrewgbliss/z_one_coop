class_name Level extends Node2D

@export var player_one_spawner: Node2D
@export var player_two_spawner: Node2D
@export var camera: Camera2D
@export var phantom_camera: PhantomCamera2D
@export var camera_target: NodePath
@export var hud: Hud
@export var show_hud: bool = true
@export var zoom: Vector2 = Vector2(2.0, 2.0)
@export var follow: bool = true

var player_one: CharacterController
var player_two: CharacterController

func _ready() -> void:
	call_deferred("_after_ready")

func _after_ready():
	if GameManager.game_state != GameManager.GAME_STATE.GAME_PLAY:
		GameManager.set_state(GameManager.GAME_STATE.GAME_PLAY)
		_spawn_players(true)
	elif GameManager.game_state == GameManager.GAME_STATE.GAME_PLAY:
		_spawn_players(false)
		
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()
		if GameManager.is_paused:
			UiManager.game_menus.push("PauseMenu")
		else:
			UiManager.game_menus.pop_all()

func _spawn_players(reset_player = false):
	player_one = SpawnManager.spawn("link", player_one_spawner.global_position, self)
	if reset_player:
		player_one.blackboard.full_reset()
	else:
		player_one.blackboard.restore()
	if hud:
		hud.setup_player_ui(player_one)
	player_one.controls.set_device_index(0)
	
	if GameManager.how_many_players == 2:
		player_two = SpawnManager.spawn("link", player_two_spawner.global_position, self)
		if reset_player:
			player_two.blackboard.full_reset()
		else:
			player_two.blackboard.restore()
		if hud:
			hud.setup_player_ui(player_two)
		player_two.controls.set_device_index(1)
	call_deferred("_set_camera")
	
	if show_hud:
		hud.show_hud()
	
func _set_camera():
	if follow:
		if player_two:
			phantom_camera.follow_mode = PhantomCamera2D.FollowMode.GROUP
			var players: Array[Node2D] = [player_one, player_two]
			phantom_camera.follow_targets = players
			phantom_camera.follow_target = null
		else:
			phantom_camera.follow_mode = PhantomCamera2D.FollowMode.FRAMED
			phantom_camera.follow_target = player_one
			phantom_camera.dead_zone_width = 0.15
			phantom_camera.dead_zone_height = 0.15
			phantom_camera.zoom = zoom
		phantom_camera.teleport_position()
	camera.make_current()

func change_camera_area(area: Area2D):
	phantom_camera.limit_target = area.get_child(0).get_path()
	_set_camera()
