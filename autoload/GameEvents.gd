extends Node

var init_inventory : bool = false

signal change_level_request(level_path : String, spawn_name : String)
signal start_battle(battle_path : String)
var rival_event_done = false
var _world_node: Node = null


signal combat_rival_finished(player_won: bool, enemy_name: String)
signal combat_rival_cancelled(enemy_name: String) # --- NUEVA SEÑAL ---

func register_world_node(node: Node) -> void:
	_world_node = node

func end_battle(player_won: bool, enemy_name: String) -> void:
	combat_rival_finished.emit(player_won, enemy_name)
	
	# Buscamos a main.gd y le ordenamos que limpie la interfaz y devuelva al jugador
	if _world_node and _world_node.has_method("_end_battle_and_return"):
		_world_node._end_battle_and_return.call_deferred()

func end_combat() -> void:
	combat_rival_finished.emit(true, "RivalLevel2")
	
func cancel_battle(enemy_name: String) -> void:
	print("[GameEvents] Batalla cancelada en el diálogo para: ", enemy_name)
	combat_rival_cancelled.emit(enemy_name) # Emitimos la cancelación en vez de derrota
