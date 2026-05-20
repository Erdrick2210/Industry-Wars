extends Area2D
class_name StartConsole

@export var texture_normal: Texture2D
@export var texture_pressed: Texture2D

@onready var sprite = $Sprite2D

var has_been_pulled: bool = false
var inside: bool = false

func _ready():
	if sprite and texture_normal:
		sprite.texture = texture_normal

func interact():
	if not has_been_pulled:
		print("Start Console used! Booting up puzzle...")
		has_been_pulled = true
		
		player_press(0.2)
		
		var cave = get_parent().get_parent()
		
		if cave and cave.has_method("begin_puzzle"):
			cave.begin_puzzle()
	else:
		print("The console is locked. The puzzle is already active!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = false

func player_press(duration: float = 0.2):
	if sprite and texture_pressed:
		sprite.texture = texture_pressed
	
	await get_tree().create_timer(duration).timeout
	
	if sprite and texture_normal:
		sprite.texture = texture_normal

func reset_console():
	has_been_pulled = false
	print("Console unlocked. Ready for another attempt!")
