extends InteractableNPC

@export var path_node: Path2D

var path_points: PackedVector2Array
var current_point_index: int = 0
var is_interacting: bool = false

func _ready() -> void:
	super._ready()
	
	if path_node and path_node.curve:
		path_points = path_node.curve.get_baked_points()
		if path_points.size() > 0:
			global_position = path_node.to_global(path_points[0])

func _physics_process(delta: float) -> void:
	if is_interacting:
		velocity = Vector2.ZERO
		super._update_look_direction()
		return

	if path_points.size() == 0:
		return

	var global_target = path_node.to_global(path_points[current_point_index])
	var towards_target = global_target - global_position
	
	if towards_target.length() < 5.0:
		current_point_index += 1
		if current_point_index >= path_points.size():
			current_point_index = 0
		return

	var direction = towards_target.normalized()
	velocity = direction * speed
	move_and_slide()

	_update_walk_animation(direction)

func _update_walk_animation(dir: Vector2) -> void:
	if not animation_sprite: return
	
	if abs(dir.x) > abs(dir.y):
		animation_sprite.play("run_right" if dir.x > 0 else "run_left")
	else:
		animation_sprite.play("run_down" if dir.y > 0 else "run_up")

func interact() -> void:
	is_interacting = true
	
	await get_tree().create_timer(3.0).timeout
	
	is_interacting = false
