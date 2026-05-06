extends Node2D

@export var level : Array[PackedScene]

var _current_level: int = 1
var _instantiated_level : Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_level(_current_level)

func _create_level(level_num : int):
	_instantiated_level = level[level_num - 1].instantiate()
	add_child(_instantiated_level)

func _eliminate_level():
	_instantiated_level.queue_free()
