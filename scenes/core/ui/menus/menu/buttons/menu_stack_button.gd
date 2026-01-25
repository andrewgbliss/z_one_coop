class_name MenuStackButton extends Button

@export var menu_stack: MenuStack
@export var to_menu: Menu

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	menu_stack.push(to_menu.name)
