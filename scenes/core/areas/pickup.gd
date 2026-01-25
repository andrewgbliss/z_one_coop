class_name Pickup extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var text: String
@export var offset: Vector2
@export var duration: float = 1.0
@export var color: Color = Color.WHITE
@export var item: Item
@export var audio_name: String
@export var wait_time: float = 1.0

var enabled = true
var collision_body
var local_collision_pos: Vector2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not enabled:
		return
	disable()
	sprite.hide()
	collision_body = body
	var collision_position = local_collision_pos + get_position()
	if collision_position:
		SpawnManager.float_text(text, collision_position + offset, duration, null, color)
	if body and body.has_method("item_pickup"):
		if item:
			body.item_pickup(item)
	AudioManager.play(audio_name)
	await get_tree().create_timer(wait_time).timeout
	call_deferred("queue_free")
	
func enable():
	enabled = true

func disable():
	enabled = false
