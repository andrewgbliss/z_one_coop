class_name Explosion extends Node2D

@export var animation_player: AnimationPlayer
@export var animation_name: String = "Explosion"
@export var audio: AudioStreamPlayer2D
@export var run_on_ready: bool = false
@export var animated_sprite: AnimatedSprite2D

func _ready():
	hide()
	call_deferred("_after_ready")

func _after_ready():
	if not run_on_ready:
		return
	run()

func run():
	show()
	if not is_inside_tree():
		return
	if audio != null:
		audio.play()
	if animation_player:
		animation_player.play(animation_name)
		await animation_player.animation_finished
	if animated_sprite:
		animated_sprite.play(animation_name)
		await animated_sprite.animation_finished
	call_deferred("queue_free")
