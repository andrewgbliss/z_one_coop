class_name CameraArea2D extends Area2D

@export var camera: PhantomCamera2D

func _ready() -> void:
  body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
  if body is CharacterController:
    camera.limit_target = get_node("CollisionShape2D").get_path()
    camera.teleport_position()
