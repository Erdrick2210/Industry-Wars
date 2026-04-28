extends CharacterBody2D

const SPEED = 500.0

# Grab the Sprite2D node so we can flip it (optional)
@onready var sprite = $PlayerMovement

var last_direction = "up"

func _physics_process(_delta):
	
	if Input.is_action_pressed("left"):
		# Use the built-in velocity.x!
		velocity.x = -SPEED
		last_direction = "left"
		sprite.flip_h = true # Optional: mirrors the sprite to face left
		
	elif Input.is_action_pressed("right"):
		# Use the built-in velocity.x!
		velocity.x = SPEED
		last_direction = "right"
		sprite.flip_h = false # Optional: keeps the sprite facing right
		
	else:
		# SLOW DOWN AND STOP when no keys are pressed
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Prevent the player from walking off the screen
	var screen_width = get_viewport_rect().size.x
	position.x = clamp(position.x, -960, 960)

	# move_and_slide uses the built-in Vector2 velocity automatically
	move_and_slide()


# --- Catching Logic ---
func _on_catch_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("fireballs"):
		# Tell the parent node (MinigameLevel) to increase the score
		get_parent().fireball_caught()
		
		# Destroy the fireball
		area.queue_free()
