extends CharacterBody2D

@export var PlayerAnimation : AnimatedSprite2D

var _walking_speed : float = 150.0
var jump_velocity : float = -400.0
var coins : int = 0
var last_direction = "right"

func _ready() -> void:
	PlayerAnimation.flip_h = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = jump_velocity
	
	var direction := Input.get_axis("left", "right")
	
	if direction != 0:
		velocity.x = direction * _walking_speed
		if direction < 0:
			last_direction = "left"
		else:
			last_direction = "right"
	else:
		velocity.x = move_toward(velocity.x, 0, _walking_speed)
	
	move_and_slide()
	
	if not is_on_floor():
		PlayerAnimation.play("jump_" + last_direction)
	else:
		if velocity.x != 0:
			PlayerAnimation.play("run_" + last_direction)
		else:
			PlayerAnimation.play("idle_" + last_direction)

func add_coin() -> void:
	coins += 1
	print("¡Tornillo recogido! Total: ", coins)
