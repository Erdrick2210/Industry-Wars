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
	
	# 1. Guardamos el nombre bonito y la cantidad en el Autoload global de Inventory
	var def = ItemDB.get_item(item_id)
	Inventory.last_picked_name = def.display_name if def else item_id
	Inventory.last_picked_qty = 1 # Tu función añade de 1 en 1
	
	# 2. Añadimos el objeto de forma silenciosa al inventario real
	Inventory.add_item(item_id)
	
	# 3. Cargamos y lanzamos el diálogo reteniendo al jugador
	var dialogue_res = load("res://game/dialogues/item_notification.dialogue")
	if dialogue_res:
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("set_frozen"):
			player.set_frozen(true)
			
		# Detiene la ejecución aquí hasta que el jugador pulse aceptar/avanzar
		await DialogueManager.show_dialogue_balloon(dialogue_res, "recogido")
		
		if player and player.has_method("set_frozen"):
			player.set_frozen(false)
			
	# 4. Una vez cerrado el diálogo, el objeto se destruye limpiamente de la escena
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
