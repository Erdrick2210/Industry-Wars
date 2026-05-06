extends Area2D
class_name InteractableItem

@export var int_id : int 
var inside : bool = false

func interact():
	match int_id:
		0:
			pickup_item()
		1:
			print("<-- Junkyard. Forest -->")
		2:
			print("<-- Casa Rival")

func pickup_item():
	print("Item picked up")
	# Añador logica de item al inventario
	# Desaparicion del item
	if owner:
		owner.queue_free()
	else:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = true
		print("Jugador detectado")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): inside = false
