extends InteractableNPC

# Exportamos las variables para poder asignar el diálogo desde el Inspector de Godot
@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "league_boss_intro" #

func interact() -> void:
	if not dialogue_resource:
		print("Error: Diálogo no asignado en este NPC interactuable")
		return
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	await DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
	
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(false)
