extends CharacterBody2D

@export var speed: float = 200.0       # Higher speed to simulate running
@export var switch_time: float = 1.5   # How many seconds they run before turning around

var direction: int = 1                 # 1 for right, -1 for left
var timer: float = 0.0

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# Add the time that passed this frame to our timer
	timer += delta
	
	# If the time is up, OR if the NPC crashes into a wall
	if timer >= switch_time or is_on_wall():
		direction *= -1     # Flip direction between 1 and -1
		timer = 0.0         # Reset the timer
		
	# Apply the speed to the velocity
	velocity.x = direction * speed
	
	# Update the animations based on which way they are running
	if direction == 1:
		anim.play("run_right") # Make sure this matches your exact animation name!
	else:
		anim.play("run_left")  # Make sure this matches your exact animation name!
		
	# Move the character and handle physics
	move_and_slide()
