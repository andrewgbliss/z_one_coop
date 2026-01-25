class_name MenuPlayButton extends Button

@export var menu_stack: MenuStack

func _ready() -> void:
	pressed.connect(_on_button_pressed)
	
func _on_button_pressed() -> void:
	menu_stack.finished.connect(_on_menu_stack_finished)
	menu_stack.pop()
	
func _on_menu_stack_finished():
	menu_stack.finished.disconnect(_on_menu_stack_finished)
	GameManager.set_state(GameManager.GAME_STATE.GAME_PLAY)
