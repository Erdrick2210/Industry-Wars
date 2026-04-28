extends Area2D

@export var rival : CharacterBody2D # Arrastra tu rival aquí en el inspector

func _on_body_entered(body):
	if body.is_in_group("Player"):
		rival.global_position = Vector2(2600, 16)
		if body.has_method("set_frozen"):
			body.set_frozen(true)
		
		
		rival.visible = true
		rival.process_mode = Node.PROCESS_MODE_INHERIT # Lo "despierta"
		
		
		queue_free()
