extends Node2D
@onready var player = $playerActions
@onready var WarpZoneLvl2 = $WarpZoneLevel2
@export var spawn_name : String = ""


func prepare_level() -> void:
	WarpZoneLvl2.set_deferred("monitoring", false)
	WarpZoneLvl2.set_deferred("monitorable", false)
	await get_tree().process_frame

	if GameManager.target_spawn_name == "FromLevel2":	
		player_entry()
		GameManager.target_spawn_name = ""
	else:
		WarpZoneLvl2.set_deferred("monitoring", true)
		WarpZoneLvl2.set_deferred("monitorable", true)


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

func _on_warp_zone_level_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Level 2")
		GameEvents.emit_signal("change_level_request", 2, spawn_name)
