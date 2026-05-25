extends Area2D
class_name InteractableItem

@export var int_id : int

# Scene Transition Variables
@export_file("*.tscn") var target_level_path : String
@export var target_spawn_name : String

var inside : bool = false
var bought : bool = false

func interact():
	print("Interact function triggered! My ID is: ", int_id) 
	match int_id:
		0:
			pickup_item()
		1:
			print("<-- Junkyard. Forest -->")
		2:
			print("<-- Casa Rival")
		3:
			_change_scene()
		4:
			_buy_vending()

func pickup_item():
	print("Item picked up")
	if owner:
		owner.queue_free()
	else:
		queue_free()

func _change_scene():
	GameEvents.emit_signal("change_level_request", target_level_path, target_spawn_name)

func _buy_vending():
	print("Item bought")
	bought = true

func has_bought():
	return bought

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = true
		print("Jugador detectado")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = false
