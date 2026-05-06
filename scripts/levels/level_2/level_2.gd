extends Node2D

@onready var player = $Player
@export_file("res://game/levels/level1.tscn") var level_1 : String
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
	
	


func _on_warp_zone_level_1_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file(level_1)
