class_name SceneGotoButton extends Button

@export var scene: String

func _ready() -> void:
	pressed.connect(_on_pressed)
	
func _on_pressed():
	SceneManager.goto_scene(scene)
