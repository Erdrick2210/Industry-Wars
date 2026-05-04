extends Node2D

@export var fireball_scene: PackedScene

signal game_over

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
	progress_bar.value = 0

func _on_spawn_timer_timeout():
	# Stop spawning if we reached 100
	if fireballs_spawned >= max_fireballs:
		$SpawnTimer.stop()
		return
		
	var random_x = randf_range(-350, 350)
	var fireball = fireball_scene.instantiate()
	fireball.position = Vector2(random_x, -550)
	add_child(fireball)
	
	fireballs_spawned += 1

# --- Scoring Functions ---

func fireball_caught():
	fireballs_caught += 1
	
	# 3. Update the UI every time a fireball is caught
	progress_bar.value = fireballs_caught
	
	check_game_over()

func check_game_over():
	fireballs_resolved += 1
	
	if fireballs_caught >= fireballs_needed_to_win:
		print("LEVEL PASSED!")
		$SpawnTimer.stop() 
		
		# 1. Quitamos la pausa para que el Nivel Principal vuelva a moverse
		game_over.emit(true) 
		
		return 
	
	if fireballs_resolved >= max_fireballs:
		print("LEVEL FAILED.")
		$SpawnTimer.stop()
		# Si pierden, también puedes quitar la pausa y destruir el minijuego
		# para que lo vuelvan a intentar desde el mapa principal.
		game_over.emit(false)
	
