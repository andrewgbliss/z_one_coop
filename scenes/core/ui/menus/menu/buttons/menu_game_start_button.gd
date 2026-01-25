class_name MenuGameStartButton extends Button

@export var user_profile_index: int

signal game_started(i: int)

func _ready() -> void:
	pressed.connect(_on_button_pressed)
	
func _on_button_pressed() -> void:
	game_started.emit(user_profile_index)
