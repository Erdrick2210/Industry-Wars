extends Node2D

@export var level : Array[PackedScene]

var _current_level: String 
var _instantiated_level : Node
var _level_cache : Dictionary = {}

func _ready() -> void:
	
	GameEvents.change_level_request.connect(_on_level_change_requested)
	# Usamos la misma función de cambio para el nivel 1 para que se guarde en cache
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
	
	if _instantiated_level.has_method("prepare_level"):
		_instantiated_level.prepare_level()


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
