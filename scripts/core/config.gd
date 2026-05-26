extends Button

const OPTIONS_MENU = preload("res://game/scenes/options_menu.tscn")

func _on_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
	var options = OPTIONS_MENU.instantiate()
	get_tree().current_scene.add_child(options)
