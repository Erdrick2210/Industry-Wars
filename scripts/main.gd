extends Node2D

@export var level : Array[PackedScene]

var _current_level: String 
var _instantiated_level : Node
var _level_cache : Dictionary = {}
var _is_returning_from_battle: bool = false

func _ready() -> void:
	GameEvents.register_world_node(self)
	GameEvents.change_level_request.connect(_on_level_change_requested)
	GameEvents.start_battle.connect(_start_battle)
	_change_level("res://game/levels/level_1/playerHome.tscn")

func _on_level_change_requested(level_path: String, spawn_name: String):
	GameManager.target_spawn_name = spawn_name
	_change_level.call_deferred(level_path)

func _change_level(level_path: String):
	if _instantiated_level:
		remove_child(_instantiated_level)
	
	_current_level = level_path
	
	if _level_cache.has(level_path):
		_instantiated_level = _level_cache[level_path]
		print("Nivel cargado desde Cache: ", level_path)
	else:
		var level_res = load(level_path)
		_instantiated_level = level_res.instantiate()
		_level_cache[level_path] = _instantiated_level
		print("Nivel instanciado por primera vez: ", level_path)
	add_child(_instantiated_level)
	
	# Esperamos un frame para que el Player y su cámara existan en el árbol
	await get_tree().process_frame
	AudioManager.play_music("res://assets/audio/music/overworld.mp3")
	
	if _instantiated_level.has_method("prepare_level"):
		_instantiated_level.prepare_level()
	
	var minimap = get_node_or_null("UICanvas/MinimapGUI")
	if minimap:
		var raw_interior = _instantiated_level.get("is_interior")
		var level_is_interior: bool = raw_interior if raw_interior != null else true
		
		minimap.player = null 
		minimap.is_interior = level_is_interior
		minimap.visible = !level_is_interior
		minimap.is_expanded = false
		minimap._update_view_mode()
		
		if not level_is_interior and is_instance_valid(minimap.viewport):
			minimap.viewport.world_2d = _instantiated_level.get_world_2d()
			
			var player_node = _instantiated_level.find_child("Player", true, false)
			if player_node:
				var cam = player_node.get_node_or_null("Camera2D")
				if cam and cam is Camera2D:
					minimap.set_map_limits(cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom)



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


func _start_battle(battle_path : String):
	# 1. Quitamos el nivel actual del Overworld del árbol
	if _instantiated_level:
		remove_child(_instantiated_level)
	
	# 2. Instanciamos la escena de batalla
	var battle_res = load(battle_path)
	_instantiated_level = battle_res.instantiate()
	
	# 3. Creamos un contenedor de Canvas Layer dinámico
	var battle_canvas = CanvasLayer.new()
	battle_canvas.name = "BattleCanvas"
	
	# 4. Enlazamos la jerarquía: Main -> CanvasLayer -> Escena de Batalla
	add_child(battle_canvas)
	battle_canvas.add_child(_instantiated_level)
	
	print("[Main] Escena de combate inyectada dentro de un CanvasLayer protector.")

func _end_battle_and_return():
	if _is_returning_from_battle:
		return
	_is_returning_from_battle = true
	
	print("[Main] Finalizando combate y preparando retorno...")
	
	# 1. Buscamos el contenedor de la batalla y lo destruimos por completo de la memoria
	var battle_canvas = get_node_or_null("BattleCanvas")
	if battle_canvas:
		battle_canvas.queue_free()
	
	# 2. Recuperamos el nivel donde se quedó el jugador usando la ruta guardada en '_current_level'
	if _current_level != "":
		_change_level(_current_level)
		AudioManager.play_music("res://assets/audio/music/overworld.mp3")
		print("[Main] Devuelto con éxito al mapa: ", _current_level)
	await get_tree().process_frame
	_is_returning_from_battle = false
