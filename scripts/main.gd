extends Node2D

@export var level : Array[PackedScene]

var _current_level: int = 1
var _instantiated_level : Node
var _level_cache : Dictionary = {}

func _ready() -> void:
	GameEvents.change_level_request.connect(_on_level_change_requested)
	# Usamos la misma función de cambio para el nivel 1 para que se guarde en cache
	_change_level(1)

func _on_level_change_requested(level_num: int, spawn_name: String):
	GameManager.target_spawn_name = spawn_name
	_change_level(level_num)

func _change_level(level_num: int):
	if _instantiated_level:
		remove_child(_instantiated_level)
	
	_current_level = level_num
	
	if _level_cache.has(level_num):
		_instantiated_level = _level_cache[level_num]
		print("Nivel cargado desde Cache: ", level_num)
	else:
		var level_res = level[level_num - 1]
		_instantiated_level = level_res.instantiate()
		_level_cache[level_num] = _instantiated_level
		print("Nivel instanciado por primera vez: ", level_num)
	add_child(_instantiated_level)
	
	if _instantiated_level.has_method("prepare_level"):
		_instantiated_level.prepare_level()
