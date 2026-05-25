extends Node2D

@export var is_interior : bool = false
@onready var player = $Player
@onready var WarpZoneLvl1 = $WarpZones/WarpZoneLevel1
@onready var WarpZoneLvl3 = $WarpZones/WarpZoneLevel3
# Descomentar per testing
# func _ready() -> void:
#	prepare_level()

func prepare_level() -> void:	
	WarpZoneLvl1.set_deferred("monitoring", false)
	WarpZoneLvl1.set_deferred("monitorable", false)
	WarpZoneLvl3.set_deferred("monitoring", false)
	WarpZoneLvl3.set_deferred("monitorable", false)
	
	player_entry()
		


func player_entry():
	player.set_physics_process(false)
	var starting_pos = player.global_position
	var anim = player.get_node("PlayerAnimation")
	if GameManager.target_spawn_name == "FromLevel1":
		anim.play("run_right")
		starting_pos += Vector2(120, 0)
	elif GameManager.target_spawn_name == "FromLevel3":
		anim.play("run_up")
		starting_pos += Vector2(0, -120)
	var tween = create_tween()
	
	
	tween.tween_property(player, "global_position", starting_pos, 1.5)
	tween.finished.connect(_finish_entry)
	

func _finish_entry():
	
	player.set_physics_process(true)
	
	WarpZoneLvl1.monitorable = true
	WarpZoneLvl1.monitoring = true
	WarpZoneLvl3.monitorable = true
	WarpZoneLvl3.monitoring = true
