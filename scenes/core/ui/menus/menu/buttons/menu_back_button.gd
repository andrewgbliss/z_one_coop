class_name MenuBackButton extends Button

var menu_stack: MenuStack
@export var unpause_game: bool = false

func _ready() -> void:
	pressed.connect(_on_button_pressed)
	_find_menu_stack()

func _find_menu_stack():
	var current_node = self
	while current_node != null:
		current_node = current_node.get_parent()
		if current_node is MenuStack:
			menu_stack = current_node
			break

func _on_button_pressed() -> void:
	menu_stack.pop()
	if unpause_game:
		get_tree().paused = false
