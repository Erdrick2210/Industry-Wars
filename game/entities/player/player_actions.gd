extends CharacterBody2D

@export var PlayerAnimation: AnimatedSprite2D

var _walking_speed : float = 120
var _running_speed : float = _walking_speed * 2
var last_direction = "down"

func _physics_process(delta: float) -> void:
	var current_speed = _walking_speed
	
	if (Input.is_action_pressed("shift")):
		current_speed = _running_speed
	
	velocity = Vector2.ZERO
	
	if(Input.is_action_pressed("up")):
		velocity.y = -1
		last_direction = "up"
	elif(Input.is_action_pressed("down")):
		velocity.y = 1
		last_direction = "down"
		
	if(Input.is_action_pressed("left")):
		velocity.x = -1
		last_direction = "left"
	elif(Input.is_action_pressed("right")):
		velocity.x = 1
		last_direction = "right"
	
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * current_speed
	
	move_and_slide()
	
	if(velocity != Vector2.ZERO):
		PlayerAnimation.speed_scale = 2 if current_speed == _running_speed else 1.0
		PlayerAnimation.play("run_" + last_direction)
	else:
		PlayerAnimation.play("idle_" + last_direction)
	
