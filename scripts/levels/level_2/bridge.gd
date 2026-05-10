extends TileMapLayer

@onready var barrier = $"../UnderPlayer/Pre-Bridge OOB/CollisionShape2D"
var combat_won : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	collision_enabled = false
	
	#Used for testing
	combat_won = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if combat_won:
		visible = true
		collision_enabled = true
		barrier.set_deferred("disabled", true)
