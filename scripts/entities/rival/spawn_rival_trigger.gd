extends Area2D

@export var rival : CharacterBody2D
@export var dialogue_resource : DialogueResource
@export var dialogue_title : String = "rival_novato"

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	
	# Evitar que se active más de una vez
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Mostrar al rival
	if rival:
		rival.global_position = Vector2(2000, 16)
		rival.visible = true
		rival.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Congelar al jugador
	#if body.has_method("set_frozen"):
	#	body.set_frozen(true)
	
	# Iniciar el diálogo
	if dialogue_resource:
		# Esperamos a que termine el diálogo usando await
		await DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title) 
	
	queue_free()
