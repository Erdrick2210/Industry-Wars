extends TileMapLayer

@onready var barrier = $"../UnderPlayer/Pre-Bridge OOB/CollisionShape2D"
var combat_won : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	collision_enabled = false
	
	if GameEvents.rival_event_done:
		activate_bridge()

func activate_bridge() -> void:
		combat_won = true
		visible = true
		collision_enabled = true
		barrier.set_deferred("disabled", true)
