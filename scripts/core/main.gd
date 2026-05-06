extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_bag()

func _toggle_bag() -> void:
	# Si ya está abierto, cierra el CanvasLayer
	for child in get_children():
		if child.name == "MenuCanvas":
			child.queue_free()
			return
	
	# Si no está abierto, lo crea
	var menu = preload("res://game/scenes/inventory/MainMenu.tscn").instantiate()
	var canvas = CanvasLayer.new()
	canvas.name = "MenuCanvas"
	add_child(canvas)
	canvas.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
