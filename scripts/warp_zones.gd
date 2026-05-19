class_name WarpZone
extends Area2D

@export_file("*.tscn") var target_level_path : String
@export var target_spawn_name : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if target_level_path == "":
			return
		print("Viajando a: ", target_level_path)
		GameEvents.emit_signal("change_level_request", target_level_path, target_spawn_name)
