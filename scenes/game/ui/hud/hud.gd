class_name Hud extends Node2D

const HEART_HP := 10
const HEART_HALF_HP := 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
			
@export var player_one_coins_label: Label
@export var player_two_coins_label: Label
@export var player_one_hearts: GridContainer
@export var player_two_hearts: GridContainer
@export var heart_texture: Texture2D
@export var heart_full_region: Rect2 = Rect2(32, 0, 16, 16)
@export var heart_half_region: Rect2 = Rect2(16, 0, 16, 16)
@export var heart_empty_region: Rect2 = Rect2(0, 0, 16, 16)
@export var restart_button: Button

var players: Array[CharacterController] = []
var _heart_full: AtlasTexture
var _heart_half: AtlasTexture
var _heart_empty: AtlasTexture

func _ready():
	player_one_coins_label.text = "0"
	player_two_coins_label.text = "0"
	# Hide player two UI until a second player is set up
	if player_two_hearts:
		player_two_hearts.get_parent().visible = false
	if heart_texture:
		_heart_full = _make_heart_atlas(heart_full_region)
		_heart_half = _make_heart_atlas(heart_half_region)
		_heart_empty = _make_heart_atlas(heart_empty_region)

func _make_heart_atlas(region: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = heart_texture
	at.region = region
	return at

func show_hud():
	animation_player.play("transition_in")
	await animation_player.animation_finished

func hide_hud():
	animation_player.play("transition_out")
	await animation_player.animation_finished
	
func _on_restart_button_pressed() -> void:
	GameManager.reset_scene()

func _on_quit_button_pressed() -> void:
	GameManager.quit()

func setup_player_ui(player: CharacterController):
	players.append(player)
	if player == players[0]:
		player.died.connect(_on_player_one_died)
		player.blackboard.inventory.gold_changed.connect(_on_player_one_coins_changed)
		player.blackboard.health_changed.connect(_on_player_one_health_changed)
		_update_hearts_container(player, player_one_hearts)
		_on_player_one_coins_changed(player.blackboard.inventory.gold)
	elif player == players[1]:
		# Show player two UI when second player joins
		if player_two_hearts:
			player_two_hearts.get_parent().visible = true
		player.blackboard.inventory.gold_changed.connect(_on_player_two_coins_changed)
		player.blackboard.health_changed.connect(_on_player_two_health_changed)
		_update_hearts_container(player, player_two_hearts)
		_on_player_two_coins_changed(player.blackboard.inventory.gold)

func _on_player_one_died(_pos: Vector2):
	restart_button.grab_focus()
	animation_player.play("die_fade_in")

func _on_player_one_coins_changed(coins: int):
	player_one_coins_label.text = str(coins)

func _on_player_two_coins_changed(coins: int):
	player_two_coins_label.text = str(coins)

func _on_player_one_health_changed(_health: int, _max_health: int):
	if players.size() > 0:
		_update_hearts_container(players[0], player_one_hearts)

func _on_player_two_health_changed(_health: int, _max_health: int):
	if players.size() > 1:
		_update_hearts_container(players[1], player_two_hearts)

func _update_hearts_container(player: CharacterController, container: GridContainer) -> void:
	if not container or not _heart_full:
		return
	var health := player.blackboard.health
	var max_health := player.blackboard.max_health
	@warning_ignore("integer_division")
	var heart_count := int(max_health / HEART_HP)
	var slot_count := container.get_child_count()
	for i in slot_count:
		var heart_rect: TextureRect = container.get_child(i) as TextureRect
		if not heart_rect:
			continue
		if i >= heart_count:
			heart_rect.visible = false
			continue
		heart_rect.visible = true
		var heart_hp_start := i * HEART_HP
		var heart_hp_mid := heart_hp_start + HEART_HALF_HP
		var heart_hp_full := heart_hp_start + HEART_HP
		if health >= heart_hp_full:
			heart_rect.texture = _heart_full
		elif health >= heart_hp_mid:
			heart_rect.texture = _heart_half
		else:
			heart_rect.texture = _heart_empty
