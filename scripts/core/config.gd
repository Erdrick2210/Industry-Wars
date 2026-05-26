extends Button

const OPTIONS_MENU = preload("res://game/scenes/options_menu.tscn")

func _on_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
	var options = OPTIONS_MENU.instantiate()
	var canvas = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(options)
	options.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
