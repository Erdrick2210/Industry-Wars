extends Node2D

@export var fireball_scene: PackedScene

# 1. Grab the reference to your new Progress Bar!
# (Make sure the path matches your Scene Tree exactly)
@onready var progress_bar = $CanvasLayer/ProgressBar

var max_fireballs: int = 100
var fireballs_spawned: int = 0
var fireballs_caught: int = 0
var fireballs_resolved: int = 0 # This counts both caught AND missed fireballs
var fireballs_needed_to_win: int = 60 # Keeps your win condition easy to change

# 2. Set up the progress bar right when the game starts
func _ready():
	progress_bar.max_value = max_fireballs
	progress_bar.value = 0

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
	
	# 3. Update the UI every time a fireball is caught
	progress_bar.value = fireballs_caught
	
	check_game_over()

func fireball_missed():
	check_game_over()

func check_game_over():
	fireballs_resolved += 1
	
	# Only evaluate the win/loss when all 100 fireballs are off the board
	if fireballs_resolved >= max_fireballs:
		if fireballs_caught >= fireballs_needed_to_win:
			print("LEVEL PASSED!")
			# Add your code here to return to the main map or show a victory screen!
		else:
			print("LEVEL FAILED. Score: ", fireballs_caught, "/", max_fireballs)
			# Add your code here to restart or kick them out!
