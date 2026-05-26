extends Button

func _on_pressed() -> void:
	GameEvents.emit_signal("change_level_request", "res://game/levels/level_1/playerHome.tscn", "DefaultSpawn")
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
