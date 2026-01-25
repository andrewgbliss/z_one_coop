class_name Explosion extends Node2D

@export var animation_player: AnimationPlayer
@export var animation_name: String = "Explode"
@export var audio: AudioStreamPlayer2D
@export var run_on_ready: bool = false

func _ready():
	call_deferred("_after_ready")

func _after_ready():
	if not run_on_ready:
		return
	run()

func run():
	if not is_inside_tree():
		return
	if audio != null:
		audio.play()
	if animation_player:
		animation_player.play(animation_name)
		await animation_player.animation_finished
	call_deferred("queue_free")
