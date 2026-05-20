extends Area2D
class_name StartConsole

# --- NEW: Texture Variables ---
@export var texture_normal: Texture2D
@export var texture_pressed: Texture2D

@onready var sprite = $Sprite2D

var has_been_pulled: bool = false
var inside: bool = false

func _ready():
	# Make sure it starts looking unpressed
	if sprite and texture_normal:
		sprite.texture = texture_normal

func interact():
	if not has_been_pulled:
		print("Start Console used! Booting up puzzle...")
		has_been_pulled = true
		
		# --- NEW: Visually press the button down! ---
		player_press(0.2)
		
		# Go up to the StartConsole folder, then up again to the Cave!
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

# --- NEW: Visual Feedback Function ---
func player_press(duration: float = 0.2):
	if sprite and texture_pressed:
		sprite.texture = texture_pressed
	
	await get_tree().create_timer(duration).timeout
	
	# Pops the button back up after 0.2 seconds. 
	# (Delete these bottom two lines if you want the button to stay pressed down permanently!)
	if sprite and texture_normal:
		sprite.texture = texture_normal
