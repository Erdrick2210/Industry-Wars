extends Node

const SAVE_PATH = "user://save_game.cfg"

func save_game() -> void:
	var config = ConfigFile.new()
	
	if is_instance_valid(GameEvents.current_player):
		config.set_value("Player", "position_x", GameEvents.current_player.global_position.x)
		config.set_value("Player", "position_y", GameEvents.current_player.global_position.y)
	else:
		config.set_value("Player", "position_x", 0.0)
		config.set_value("Player", "position_y", 0.0)
		
	config.set_value("Player", "current_level", GameEvents.current_level_path)
	
	config.set_value("Events", "init_inventory", GameEvents.init_inventory)
	config.set_value("Events", "rival_event_done", GameEvents.rival_event_done)
	config.set_value("Events", "trigger_rival_1", GameEvents.trigger_rival_1)
	config.set_value("Events", "oldman_is_running", GameEvents.oldman_is_running)
	config.set_value("Events", "lab_repaired", GameEvents.lab_repaired)
	config.set_value("Events", "mentor_event_finished", GameEvents.mentor_event_finished)
	config.set_value("Events", "bought", GameEvents.bought)
	config.set_value("Events", "collected_items", GameEvents.collected_items)
	
	if Inventory.has_method("serialize"):
		config.set_value("Inventory", "data", Inventory.serialize())
		
	if RobotParty.has_method("serialize"):
		config.set_value("Party", "robots", RobotParty.serialize())
	
	var error = config.save(SAVE_PATH)
	if error == OK:
		print("Game saved successfully!")
	else:
		print("Error saving game: ", error)

func load_game() -> void:
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		print("No save file found or error loading: ", error)
		return
		
	GameEvents.init_inventory = config.get_value("Events", "init_inventory", false)
	GameEvents.rival_event_done = config.get_value("Events", "rival_event_done", false)
	GameEvents.trigger_rival_1 = config.get_value("Events", "trigger_rival_1", false)
	GameEvents.oldman_is_running = config.get_value("Events", "oldman_is_running", true)
	GameEvents.lab_repaired = config.get_value("Events", "lab_repaired", false)
	GameEvents.mentor_event_finished = config.get_value("Events", "mentor_event_finished", false)
	GameEvents.bought = config.get_value("Events", "bought", false)
	GameEvents.collected_items = config.get_value("Events", "collected_items", {})
		
	if Inventory.has_method("deserialize"):
		var inv_data = config.get_value("Inventory", "data", {"slots": [], "equipped": {}, "time": 0})
		Inventory.deserialize(inv_data)
		
	if RobotParty.has_method("deserialize"):
		var party_data = config.get_value("Party", "robots", [])
		if not party_data.is_empty():
			RobotParty.deserialize(party_data)
		
	var target_level = config.get_value("Player", "current_level", "")
	var pos_x = config.get_value("Player", "position_x", 0.0)
	var pos_y = config.get_value("Player", "position_y", 0.0)
	
	if target_level == "" or target_level == "res://game/scenes/title_screen.tscn":
		print("Warning: Saved level path was invalid or title screen. Forcing default level.")
		target_level = "res://game/levels/level_1/playerHome.tscn"
		
	GameEvents.emit_signal("change_level_request", target_level, "LoadedPosition", Vector2(pos_x, pos_y))
	print("Game loaded successfully. Requesting level: ", target_level)
