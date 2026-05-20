extends InteractableNPC


func interact() -> void: # TODO / Implementar diàleg o el que sigui
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	await get_tree().create_timer(2.0).timeout
	
	if target_player:
		target_player.set_frozen(false)
