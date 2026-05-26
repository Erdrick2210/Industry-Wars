extends Node2D

@export var fireball_scene: PackedScene

signal game_over

@onready var progress_bar = $CanvasLayer/ProgressBar
@onready var minimap = get_parent().find_child("UICanvas", true, false)

var max_fireballs: int = 100
var fireballs_spawned: int = 0
var fireballs_caught: int = 0
var fireballs_resolved: int = 0
var fireballs_needed_to_win: int = 10

func _ready():
	progress_bar.value = 0
	if minimap:
		minimap.visible = false

func _on_spawn_timer_timeout():
	if fireballs_spawned >= max_fireballs:
		$SpawnTimer.stop()
		return
		
	var random_x = randf_range(-350, 350)
	var fireball = fireball_scene.instantiate()
	fireball.position = Vector2(random_x, -550)
	add_child(fireball)
	
	fireballs_spawned += 1

func fireball_caught():
	fireballs_caught += 1
	progress_bar.value = fireballs_caught
	check_game_over()

func check_game_over():
	fireballs_resolved += 1
	
	if fireballs_caught >= fireballs_needed_to_win:
		print("LEVEL PASSED!")
		minimap.visible = true
		$SpawnTimer.stop() 
		game_over.emit(true) 
		return 
	
	if fireballs_resolved >= max_fireballs:
		print("LEVEL FAILED.")
		minimap.visible = true
		$SpawnTimer.stop()
		game_over.emit(false)
