extends PathFollow2D

@export var speed: float = 200.0 
@export var _progress: float

@onready var sensor: RayCast2D = $"Sprite2D/StaticBody2D/RayCast2D"

func _ready() -> void:
	progress = _progress

func _process(delta: float) -> void:
	if sensor.is_colliding():
		return 
	
	progress += speed * delta
