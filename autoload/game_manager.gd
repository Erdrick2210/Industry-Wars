extends Node

# ─────────────────────────────────────────────
# ESCENAS
# ─────────────────────────────────────────────

const OVERWORLD_SCENE := "res://game/scenes/main.tscn"
const BATTLE_SCENE := "res://game/scenes/battle.tscn"

# ─────────────────────────────────────────────
# MEMORIA DE ESCENA
# ─────────────────────────────────────────────

var target_spawn_name: String = ""
var previous_scene: String = ""
# ─────────────────────────────────────────────
# NAVEGACIÓN
# ─────────────────────────────────────────────

func go_to_overworld():
	get_tree().change_scene_to_file(OVERWORLD_SCENE)

func start_battle():
	get_tree().change_scene_to_file(BATTLE_SCENE)

func return_to_previous_scene():
	if previous_scene != "":
		get_tree().change_scene_to_file(previous_scene)
	else:
		go_to_overworld()
