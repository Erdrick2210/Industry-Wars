extends Node2D

@onready var player = $Player
@export var spawn_name : String = ""
@onready var WarpZoneLvl1 = $WarpZoneLevel1
@export_file("res://game/levels/level1.tscn") var level_1 : String
# Called when the node enters the scene tree for the first time.
func prepare_level() -> void:
	WarpZoneLvl1.set_deferred("monitoring", false)
	WarpZoneLvl1.set_deferred("monitorable", false)
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
	
	WarpZoneLvl1.monitorable = true
	WarpZoneLvl1.monitoring = true


func _on_warp_zone_level_1_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Changing to level 1")
		GameEvents.emit_signal("change_level_request", 1, spawn_name)
