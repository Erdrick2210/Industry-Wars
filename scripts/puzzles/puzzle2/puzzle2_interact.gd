extends Area2D
class_name PuzzlePillar

@export var pillar_color: String 
@export var texture_normal: Texture2D
@export var texture_pressed: Texture2D
@export var texture_flash: Texture2D 

# Signal to tell the Cave scene which color was pressed
signal interacted_with_pillar(color: String)

var inside : bool = false

# Grab the sprite when the scene loads for the flash animation
@onready var sprite = $Sprite2D 

func _ready():
	# Force the sprite to show the normal texture the moment the game starts
	if sprite and texture_normal:
		sprite.texture = texture_normal

func interact():
	print("Pillar interact function triggered!") 
	_trigger_pillar()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = true
		print("Jugador detectado en pilar")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		inside = false

# --- Puzzle Functions ---

func _trigger_pillar():
	player_press(0.2) # Show the button physically go down
	interacted_with_pillar.emit(pillar_color) # Tell the Cave

# The Cave script will call this to show the glowing pattern
func sequence_flash(duration: float = 0.6):
	if sprite and texture_flash:
		sprite.texture = texture_flash
	
	await get_tree().create_timer(duration).timeout
	
	if sprite and texture_normal:
		sprite.texture = texture_normal

# We use this to briefly show the button pressed down when the player clicks it
func player_press(duration: float = 0.2):
	if sprite and texture_pressed:
		sprite.texture = texture_pressed
	
	await get_tree().create_timer(duration).timeout
	
	if sprite and texture_normal:
		sprite.texture = texture_normal
