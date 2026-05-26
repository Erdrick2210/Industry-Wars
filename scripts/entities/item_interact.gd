extends Area2D
class_name InteractableItem

@export var int_id : int
@export var item_id : String

@export_file("*.tscn") var target_level_path : String
@export var target_spawn_name : String

var inside : bool = false

func _ready() -> void:
	if int_id == 0 and item_id != "" and GameEvents.collected_items.has(item_id):
		_self_destruct()
		
	if int_id == 4 and GameEvents.bought:
		_self_destruct()

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
	if item_id != "":
		GameEvents.collected_items[item_id] = true
		GameEvents.emit_signal("item_collected", item_id)
		
	AudioManager.play_sfx("res://assets/audio/sfx/item_get.wav")
	print("Item picked up")
	Inventory.add_item(item_id)
	_self_destruct()

func _change_scene():
	AudioManager.play_sfx("res://assets/audio/sfx/door.WAV")
	GameEvents.emit_signal("change_level_request", target_level_path, target_spawn_name, Vector2.ZERO)

func _buy_vending():
	AudioManager.play_sfx("res://assets/audio/sfx/item_get.wav")
	print("Item bought")
	GameEvents.bought = true
	_self_destruct()

func has_bought():
	return GameEvents.bought

func _self_destruct() -> void:
	if owner:
		owner.queue_free()
	else:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = true
		print("Jugador detectado")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = false
