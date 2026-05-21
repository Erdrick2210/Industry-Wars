extends Node2D

@export var is_interior : bool = false
@onready var player = $Player
@onready var WarpZoneLvl1 = $WarpZones/WarpZoneLevel1

# Descomentar per testing
# func _ready() -> void:
#	prepare_level()

func prepare_level() -> void:	
	if GameManager.target_spawn_name == "FromLevel1": ## Comentar per testing
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
