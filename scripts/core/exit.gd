extends Button

func _on_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
