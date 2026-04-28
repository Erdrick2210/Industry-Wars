extends Node2D

@export var fireball_scene: PackedScene

# Select your SpawnTimer, go to Signals, and connect "timeout" here:
func _on_spawn_timer_timeout():
	# Get the width of the screen so we know where we can spawn
	var screen_width = get_viewport_rect().size.x
	
	# Pick a random spot between the left (20) and right (width - 20) edges
	var random_x = randf_range(-500, 500)
	
	# Create a new fireball
	var fireball = fireball_scene.instantiate()
	
	# Start it at the top of the screen (y = -50 hides it just above the camera)
	fireball.position = Vector2(random_x, -700)
	
	# Add it to the level
	add_child(fireball)
