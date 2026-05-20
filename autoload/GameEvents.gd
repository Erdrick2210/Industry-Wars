extends Node
signal change_level_request(level_path : String, spawn_name : String)
signal start_battle(battle_path : String)
var rival_event_done = false
var _world_node: Node = null
signal combat_rival2_finished

func register_world_node(node: Node) -> void:
	_world_node = node

func end_battle() -> void:
	print("[GameEvents] end_battle() invocado. Terminando el combate...")
	
	# Emitimos la señal por si el NPC Rival del mapa se tiene que enterar para huir
	combat_rival2_finished.emit()
	
	# Buscamos a main.gd y le ordenamos que limpie la interfaz y devuelva al jugador
	if _world_node and _world_node.has_method("_end_battle_and_return"):
		# Usamos call_deferred para que el cambio de nodos se haga de forma segura en el próximo frame
		_world_node._end_battle_and_return.call_deferred()
	else:
		push_error("[GameEvents] No se pudo regresar al Overworld porque 'main.gd' no está registrado.")

func end_combat() -> void:
	combat_rival2_finished.emit()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
