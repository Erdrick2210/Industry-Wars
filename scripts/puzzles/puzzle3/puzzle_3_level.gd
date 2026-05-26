extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			print("Tecla R presionada: Reiniciando nivel...")
			restart_level()

func _on_void_zone_body_entered(body: Node2D) -> void:
	# Verificamos directamente el nombre del nodo que cayó
	if body.name == "Player":
		print("El jugador cayó al vacío.")
		restart_level()
		
func restart_level() -> void:
	get_tree().call_deferred("reload_current_scene")
