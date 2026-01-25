class_name MenuPauseButton extends TextureButton

@export var menu_stack: MenuStack
@export var to_menu: Menu

signal game_paused

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	menu_stack.push(to_menu.name)
	game_paused.emit()
