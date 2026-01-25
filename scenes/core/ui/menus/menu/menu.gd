class_name Menu extends CanvasLayer

@export var menu_name: String = ""
@export var animation_transition_in: String = "transition_in"
@export var animation_transition_out: String = "transition_out"
@export var animation_transition_away_in: String = "transition_away_in"
@export var animation_transition_away_out: String = "transition_away_out"
@export var focus_btn: Button

@export var hide_on_ready: bool = true
@export var show_menu_on_ready: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var parent

func _ready():
	parent = get_parent()
	if hide_on_ready:
		_off()
	if show_menu_on_ready:
		transition_in()
					
func _off():
	hide()
	set_process(false)

func _on():
	show()
	set_process(true)

func transition_in():
	_on()
	animation_player.play(animation_transition_in)
	await animation_player.animation_finished
	if focus_btn:
		focus_btn.grab_focus()

func transition_out():
	animation_player.play(animation_transition_out)
	await animation_player.animation_finished
	_off()

func transition_away_in():
	_on()
	animation_player.play(animation_transition_away_in)
	await animation_player.animation_finished
	if focus_btn:
		focus_btn.grab_focus()
	
func transition_away_out():
	animation_player.play(animation_transition_away_out)
	await animation_player.animation_finished
	_off()
