class_name Pickup extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var text: String
@export var offset: Vector2 = Vector2(-8, -8)
@export var duration: float = 1.0
@export var color: Color = Color.WHITE
@export var item: Item
@export var audio_name: String
@export var garbage: bool = true
@export var garbage_time: float = 1.0
@export var respawn_time: float = 0.0

var enabled = true
var label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	_setup_cost_label()

func _setup_cost_label():
	if item and item.sell_price > 0:
		label = Label.new()
		label.text = str(item.sell_price)
		label.position = Vector2(8, 0)
		add_child(label)

func _setup_sprite() -> void:
	if item:
		sprite.texture = item.texture
		sprite.hframes = item.hframes
		sprite.vframes = item.vframes
		sprite.frame = item.frame

func _on_body_entered(body):
	if not enabled:
		return
	if item and body and body.has_method("item_pickup"):
		_handle_pickup(body)

func _handle_pickup(body):
	if body.item_pickup(item):
		_clean_up()

func _clean_up():
	disable()
	if sprite:
		sprite.hide()
	if label:
		label.hide()
	SpawnManager.float_text(text, global_position + offset, duration, null, color)
	AudioManager.play(audio_name)

	if garbage:
		await get_tree().create_timer(garbage_time).timeout
		if respawn_time > 0:
			await get_tree().create_timer(respawn_time).timeout
			show_pickup()
		else:
			call_deferred("queue_free")

	
func enable():
	enabled = true

func disable():
	enabled = false

func show_pickup():
	enabled = true
	if sprite:
		sprite.show()
	if label:
		label.show()
