extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite = $PlayerMovement2

var last_direction = "up"

func _physics_process(_delta):
	
	if Input.is_action_pressed("left"):
		velocity.x = -SPEED
		last_direction = "left"
		# Just play the animation, no flipping!
		animated_sprite.play("default")
		
	elif Input.is_action_pressed("right"):
		velocity.x = SPEED
		last_direction = "right"
		# Just play the animation, no flipping!
		animated_sprite.play("default")

	else:
		# SLOW DOWN AND STOP when no keys are pressed
		velocity.x = move_toward(velocity.x, 0, SPEED)
		# Stop the animation when standing still
	

	# Prevent the player from walking off the screen
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, -546, 546)

	# move_and_slide uses the built-in Vector2 velocity automatically
	move_and_slide()

# --- Catching Logic ---
func _on_catch_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("fireballs"):
		get_parent().fireball_caught()
		area.queue_free()
