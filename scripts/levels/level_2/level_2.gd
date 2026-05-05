extends Node2D

@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_entry()


func player_entry():
	player.set_physics_process(false)
	
	var anim = player.get_node("PlayerAnimation")
	anim.play("run_right")
	
	var tween = create_tween()
	var starting_pos = player.global_position + Vector2(120, 0)
	
	tween.tween_property(player, "global_position", starting_pos, 1.5)
	tween.finished.connect(_finish_entry)
	

func _finish_entry():
	var anim = player.get_node("PlayerAnimation")
	anim.play("idle_right")
	
	player.set_physics_process(true)
	
	
