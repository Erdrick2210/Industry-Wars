extends CharacterBody2D

# --- REFERENCIAS ---
@export var RivalAnimation : AnimatedSprite2D

# --- CONFIGURACIÓN ---
@export var walking_speed : float = 120.0
@export var patrol_range : float = 200.0

# --- VARIABLES INTERNAS ---
var _home_position : Vector2
var _direction : int = 1 

# Definimos estados: PATROL para moverse, IDLE para quedarse quieto
enum State { PATROL, IDLE }
var current_state : State = State.PATROL

func _ready() -> void:
	_home_position = global_position
	RivalAnimation.play("run_down")

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.PATROL:
			_process_patrol()
	
	move_and_slide()

# --- LÓGICA DE ESTADOS ---

func _process_idle() -> void:
	velocity = Vector2.ZERO
	# Aquí puedes cambiar a la animación de "idle" que tengas configurada
	RivalAnimation.play("idle_left") 

func _process_patrol() -> void:
	velocity.x = 0
	velocity.y = _direction * walking_speed
	
	if global_position.y > _home_position.y + patrol_range and _direction == 1:
		_direction = -1
		RivalAnimation.play("run_up")
	elif global_position.y < _home_position.y and _direction == -1:
		_direction = 1
		RivalAnimation.play("run_down")

# --- FUNCIONES DE APOYO ---

func _change_state(new_state: State) -> void:
	current_state = new_state

# --- SEÑALES ---

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		print("¡Te veo! Me quedo quieto.")
		_change_state(State.IDLE)
		
		body.set_frozen(true)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Has huido. Sigo patrullando.")
		_change_state(State.PATROL)
