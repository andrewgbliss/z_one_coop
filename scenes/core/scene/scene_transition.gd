class_name SceneTransition extends CanvasLayer

@export var animation_transition_in: String = "transition_in"
@export var animation_transition_out: String = "transition_out"
@export var animation_blink: String = "blink"
@export var next_transition: SceneTransition
@export var time_to_live: float = 0.0
@export var any_key_to_next: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_blinking: bool = false
var did_go_to_next: bool = false

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_anything_pressed() and any_key_to_next and not did_go_to_next and visible:
		did_go_to_next = true
		var next_t = await next()
		if next_t:
			SceneManager.transition_play(next_t.name)

func _ready():
	hide()
				
func play():
	await transition_in()
	if animation_blink != "" and not did_go_to_next:
		await blink()
	if time_to_live > 0.0 and not did_go_to_next:
		await get_tree().create_timer(time_to_live).timeout
		if did_go_to_next:
			return
		var next_t = await next()
		if next_t:
			SceneManager.transition_play(next_t.name)

func transition_in():
	if animation_player and not did_go_to_next:
		show()
		animation_player.play(animation_transition_in)
		await animation_player.animation_finished

func blink():
	if animation_player:
		is_blinking = true
		animation_player.play(animation_blink)
		await animation_player.animation_finished
		is_blinking = false

func transition_out():
	if animation_player:
		animation_player.play(animation_transition_out)
		await animation_player.animation_finished
	hide()

func next():
	is_blinking = false
	await transition_out()
	return next_transition
