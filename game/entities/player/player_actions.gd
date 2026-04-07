extends CharacterBody2D

@export var PlayerAnimation: AnimatedSprite2D

var _player_speed : float = 80
var last_direction = "down"

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if(Input.is_action_pressed("up")):
		velocity.y = -_player_speed
		last_direction = "up"
	elif(Input.is_action_pressed("left")):
		velocity.x = -_player_speed
		last_direction = "left"
	elif(Input.is_action_pressed("down")):
		velocity.y = _player_speed
		last_direction = "down"
	elif(Input.is_action_pressed("right")):
		velocity.x = _player_speed
		last_direction = "right"
	
	move_and_slide()
	
	if(velocity != Vector2.ZERO):
		PlayerAnimation.play("run_" + last_direction)
	else:
		PlayerAnimation.play("idle_" + last_direction)
	
