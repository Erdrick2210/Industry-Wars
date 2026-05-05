extends CharacterBody2D

@export var PlayerAnimation: AnimatedSprite2D

var interactable = null
var _walking_speed : float = 120
var _running_speed : float = _walking_speed * 2
var last_direction = "down"

# Variable para controlar el estado
var is_frozen : bool = false 

func _physics_process(delta: float) -> void:
	# --- LÓGICA DE CONGELAMIENTO ---
	if is_frozen:
		velocity = Vector2.ZERO
		PlayerAnimation.play("idle_" + last_direction)
		return # <-- "Early Return": Ignora el resto del código si está congelado

	# --- LÓGICA DE MOVIMIENTO ---
	var current_speed = _walking_speed
	
	if (Input.is_action_pressed("shift")):
		current_speed = _running_speed
	
	velocity = Vector2.ZERO
	
	if(Input.is_action_pressed("up")):
		velocity.y = -1
		last_direction = "up"
	elif(Input.is_action_pressed("down")):
		velocity.y = 1
		last_direction = "down"
		
	if(Input.is_action_pressed("left")):
		velocity.x = -1
		last_direction = "left"
	elif(Input.is_action_pressed("right")):
		velocity.x = 1
		last_direction = "right"
	
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * current_speed
	
	move_and_slide()
	
	# --- LÓGICA DE ANIMACIÓN ---
	if(velocity != Vector2.ZERO):
		PlayerAnimation.speed_scale = 2 if current_speed == _running_speed else 1.0
		PlayerAnimation.play("run_" + last_direction)
	else:
		PlayerAnimation.play("idle_" + last_direction)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if interactable and interactable.has_method("interact"):
			interactable.interact()


# Función pública para que el NPC pueda llamarla
func set_frozen(value: bool):
	is_frozen = value


func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		interactable = area
	elif area.get_parent().has_method("interact"):
		interactable = area.get_parent()


func _on_interaction_area_area_exited(area: Area2D) -> void:
	if interactable == area or interactable == area.get_parent():
		interactable = null # Replace with function body.
