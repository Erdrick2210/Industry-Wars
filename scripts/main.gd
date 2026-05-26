extends Node2D

@export var level : Array[PackedScene]
@export var player : PackedScene

var _current_level: String 
var _instantiated_level : Node
var _level_cache : Dictionary = {}
var _is_returning_from_battle: bool = false
var _pending_forced_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameEvents.register_world_node(self)
	GameEvents.change_level_request.connect(_on_level_change_requested)
	GameEvents.start_battle.connect(_start_battle)
	
	await get_tree().process_frame
	
	_change_level("res://game/scenes/title_screen.tscn")

func _on_level_change_requested(level_path: String, spawn_name: String, forced_position: Vector2 = Vector2.ZERO):
	if forced_position != Vector2.ZERO:
		_pending_forced_position = forced_position
		
	GameManager.target_spawn_name = spawn_name
	_change_level(level_path)

func _change_level(level_path: String):
	if _instantiated_level:
		remove_child(_instantiated_level)
	
	_current_level = level_path
	
	# ESTA LÍNEA ES CRUCIAL: Guarda la ruta antes de filtrar o instanciar
	GameEvents.current_level_path = level_path
	
	if level_path == "res://game/scenes/title_screen.tscn":
		var level_res = load(level_path)
		_instantiated_level = level_res.instantiate()
		add_child(_instantiated_level)
		await get_tree().process_frame
		return

	if _level_cache.has(level_path):
		_instantiated_level = _level_cache[level_path]
		print("Level loaded from cache: ", level_path)
	else:
		var level_res = load(level_path)
		_instantiated_level = level_res.instantiate()
		_level_cache[level_path] = _instantiated_level
		print("Level instantiated for the first time: ", level_path)
		
	add_child(_instantiated_level)
	
	await get_tree().process_frame
	
	if _pending_forced_position != Vector2.ZERO:
		if is_instance_valid(GameEvents.current_player):
			GameEvents.current_player.global_position = _pending_forced_position
		_pending_forced_position = Vector2.ZERO
	
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
	for child in get_children():
		if child.name == "MenuCanvas":
			child.queue_free()
			return
	
	var menu = preload("res://game/scenes/inventory/MainMenu.tscn").instantiate()
	var canvas = CanvasLayer.new()
	canvas.name = "MenuCanvas"
	add_child(canvas)
	canvas.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _start_battle(battle_path : String):
	if _instantiated_level:
		remove_child(_instantiated_level)
	
	var battle_res = load(battle_path)
	_instantiated_level = battle_res.instantiate()
	
	var battle_canvas = CanvasLayer.new()
	battle_canvas.name = "BattleCanvas"
	
	add_child(battle_canvas)
	battle_canvas.add_child(_instantiated_level)
	
	print("[Main] Battle scene injected within protective CanvasLayer.")

func _end_battle_and_return():
	if _is_returning_from_battle:
		return
	_is_returning_from_battle = true
	
	print("[Main] Ending battle and preparing return...")
	
	var battle_canvas = get_node_or_null("BattleCanvas")
	if battle_canvas:
		battle_canvas.queue_free()
	
	if _current_level != "":
		_change_level(_current_level)
		AudioManager.play_music("res://assets/audio/music/overworld.mp3")
		print("[Main] Successfully returned to map: ", _current_level)
	await get_tree().process_frame
	_is_returning_from_battle = false
