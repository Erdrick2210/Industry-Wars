extends Area2D

@export var texture_closed: Texture2D
@export var texture_open: Texture2D

@onready var sprite = $Sprite2D
var is_open: bool = false
var is_locked: bool = true 

func _ready():
	if sprite and texture_closed:
		sprite.texture = texture_closed

func interact():
	if is_locked:
		print("The chest is magically sealed. Solve the puzzle first!")
		return 

	if not is_open:
		is_open = true

		if sprite and texture_open:
			sprite.texture = texture_open
			
		print("Chest opened! You got a reward!")

func unlock():
	is_locked = false
	print("You hear a loud click. The chest is unlocked!")
