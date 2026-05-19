extends Node2D
@onready var player = $playerActions
@onready var mentor = $Mentor 
@onready var WarpZoneLvl2 = $WarpZoneLevel2


func prepare_level() -> void:
	WarpZoneLvl2.set_deferred("monitoring", false)
	WarpZoneLvl2.set_deferred("monitorable", false)
	await get_tree().process_frame

	if GameManager.target_spawn_name == "FromLevel2":	
		player_entry()
	else:
		WarpZoneLvl2.set_deferred("monitoring", true)
		WarpZoneLvl2.set_deferred("monitorable", true)
	
	if mentor and mentor.has_method("prepare_npc"):
		mentor.prepare_npc()


func player_entry():
	player.set_physics_process(false)
	
	var anim = player.get_node("PlayerAnimation")
	anim.play("run_left")
	
	var tween = create_tween()
	var target_pos = player.global_position - Vector2(120, 0)
	tween.tween_property(player, "global_position", target_pos, 1.5)
	
	tween.finished.connect(_finish_entry)

func _finish_entry():
	var anim = player.get_node("PlayerAnimation")
	anim.play("idle_left")
	
	player.set_physics_process(true)
	
	if is_instance_valid(WarpZoneLvl2):
		await get_tree().create_timer(0.5).timeout
		WarpZoneLvl2.monitorable = true
		WarpZoneLvl2.monitoring = true
