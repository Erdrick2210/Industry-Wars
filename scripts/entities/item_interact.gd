extends Area2D
class_name InteractableItem

@export var int_id : int = 0
var inside : bool = false

func interact():
	if int_id:
		if int_id == 1:
			print("Hola")
	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): inside = false
