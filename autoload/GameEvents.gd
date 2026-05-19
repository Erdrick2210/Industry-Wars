extends Node
signal change_level_request(level_path : String, spawn_name : String)
var rival_event_done = false
signal combat_rival2_finished

func end_combat() -> void:
	combat_rival2_finished.emit()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
