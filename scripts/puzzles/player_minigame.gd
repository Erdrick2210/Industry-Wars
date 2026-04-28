extends Node2D

@export var fireball_scene: PackedScene

var max_fireballs: int = 100
var fireballs_spawned: int = 0
var fireballs_caught: int = 0
var fireballs_resolved: int = 0 # This counts both caught AND missed fireballs

func _on_spawn_timer_timeout():
	# Stop spawning if we reached 100
	if fireballs_spawned >= max_fireballs:
		$SpawnTimer.stop()
		return
		
	var random_x = randf_range(-500, 500)
	var fireball = fireball_scene.instantiate()
	fireball.position = Vector2(random_x, -700)
	add_child(fireball)
	
	fireballs_spawned += 1

# --- Scoring Functions ---

func fireball_caught():
	fireballs_caught += 1
	check_game_over()

func fireball_missed():
	check_game_over()

func check_game_over():
	fireballs_resolved += 1
	
	# Only evaluate the win/loss when all 100 fireballs are off the board
	if fireballs_resolved >= max_fireballs:
		if fireballs_caught >= 60:
			print("LEVEL PASSED!")
			# Add your code here to return to the main map or show a victory screen!
		else:
			print("LEVEL FAILED. Score: ", fireballs_caught, "/100")
			# Add your code here to restart or kick them out!
