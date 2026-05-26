extends Node

var init_inventory : bool = false
var current_level_path : String = ""
var _world_node: Node = null
var current_player: CharacterBody2D = null
var collected_items : Dictionary = {}

var trigger_rival_1 : bool = false
var oldman_is_running: bool = true
var lab_repaired : bool = false
var rival_event_done : bool = false
var mentor_event_finished : bool = false


signal item_collected(item_id : String)
signal change_level_request(level_path : String, spawn_name : String, forced_position : Vector2)
signal start_battle(battle_path : String)
signal combat_rival_finished(player_won: bool, enemy_name: String)
signal combat_rival_cancelled(enemy_name: String)

var bought : bool = false

func register_world_node(node: Node) -> void:
	_world_node = node

func end_battle(player_won: bool, enemy_name: String) -> void:
	combat_rival_finished.emit(player_won, enemy_name)
	
	if _world_node and _world_node.has_method("_end_battle_and_return"):
		_world_node._end_battle_and_return.call_deferred()

func end_combat() -> void:
	combat_rival_finished.emit(true, "RivalLevel2")
	
func cancel_battle(enemy_name: String) -> void:
	print("[GameEvents] Battle cancelled in dialogue for: ", enemy_name)
	combat_rival_cancelled.emit(enemy_name)
