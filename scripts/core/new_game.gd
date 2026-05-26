extends Button

func _on_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
	get_tree().change_scene_to_file("res://game/scenes/main.tscn")
