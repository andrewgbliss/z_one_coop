class_name CameraArea2D extends Area2D

@export var level: int

var camera: PhantomCamera2D

func _ready() -> void:
	camera = get_tree().root.get_node("Overworld/PhantomCamera2D")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterController:
		if body.blackboard:
			print(body.name)
			body.blackboard.change_level(level)
		if camera:
			camera.limit_target = get_node("CollisionShape2D").get_path()
			camera.teleport_position()
		else:
			print("No camera", name)
