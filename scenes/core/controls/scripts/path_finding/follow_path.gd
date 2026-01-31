class_name FollowPath extends CharacterBaseNode
 
@export var speed: float = 0.1

var path_follow: PathFollow2D

func _ready():
	super ()
	parent.parent_path_created.connect(_on_parent_path_created)

func _on_parent_path_created(path: Path2D):
	path_follow = path.get_node("PathFollow2D")
	path_follow.progress_ratio = 0.0

func _physics_process(_delta: float) -> void:
	parent.move()

func _process(delta: float) -> void:
	if not path_follow:
		return
	path_follow.progress_ratio += speed * delta
	calc_target_movement_direction()

func calc_target_movement_direction():
	if path_follow == null:
		parent.controls.target_movement_direction = Vector2.ZERO
		return
	parent.controls.target_movement_direction = (path_follow.global_position - parent.global_position).normalized()
