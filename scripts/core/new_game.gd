extends Button

var files = [
		"user://save_game.cfg",
		"user://save_game.json"
	]
	
func _on_pressed() -> void:
	for path in files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	GameEvents.emit_signal("change_level_request", "res://game/levels/level_1/playerHome.tscn", "DefaultSpawn")
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
