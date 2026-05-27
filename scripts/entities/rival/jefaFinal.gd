extends InteractableNPC

@export var dialogue_resource: DialogueResource

var is_busy: bool = false


func interact() -> void:
	print("hola")
	get_tree().change_scene_to_file("res://game/scenes/credits_scene.tscn")
	_lanzar_dialogo_encuentro()
	_go_to_credits()
	print("check")


func _lanzar_dialogo_encuentro() -> void:
	var dialog = load("res://game/dialogues/jefa_encuentro.dialogue")

	if dialog:
		DialogueManager.show_dialogue_balloon(dialog, "league_boss_intro")
		# esperamos un tiempo fijo o señal externa
		await get_tree().create_timer(3.0).timeout

		_go_to_credits()
	else:
		print("Error diálogo jefa")


func _go_to_credits() -> void:
	print(">>> CAMBIANDO A CRÉDITOS")
	get_tree().change_scene_to_file("res://game/scenes/credits_scene.tscn")
