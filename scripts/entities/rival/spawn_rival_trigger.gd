extends Area2D

@export var rival : CharacterBody2D

func _on_body_entered(body: Node2D) -> void:
	if !GameEvents.trigger_rival_1:
		if not body.is_in_group("Player"):
			return
		
		# Evitar que se active más de una vez el trigger del suelo
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# Mostrar y activar al rival
		if rival:
			rival.global_position = Vector2(2000, 16)
			rival.visible = true
			rival.process_mode = Node.PROCESS_MODE_INHERIT
			
			# Le pasamos la referencia del jugador directamente para iniciar el CHASE_STOP
			if rival.has_method("_on_detection_area_2_body_entered"):
				rival._on_detection_area_2_body_entered(body)
		
		# Congelar al jugador preventivamente para la escena
		if body.has_method("set_frozen"):
			body.set_frozen(true)
		GameEvents.trigger_rival_1 = true
		# Eliminamos el trigger de suelo de forma segura
		queue_free()
		
