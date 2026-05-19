extends InteractableNPC

# --- REFERENCIAS ---
@export var enable_detection : bool = true 
@onready var detection_area = $DetectionArea2

# --- VARIABLES INTERNAS ---
enum State { PATROL, CHASE_STOP, IDLE } # Añadimos un estado para frenar con precisión
var current_state : State = State.PATROL
var _target_player : Node2D = null

func _ready() -> void:
	if not enable_detection:
		detection_area.monitoring = false
		detection_area.monitorable = false
		detection_area.visible = false
	
	animation_sprite.play("run_left")

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.PATROL:
			_process_patrol()
		State.CHASE_STOP:
			_process_chase_stop()
	
	move_and_slide()

func _process_idle() -> void:
	velocity = Vector2.ZERO
	animation_sprite.play("idle_left")

func _process_patrol() -> void:
	# El NPC patrulla hacia la izquierda de forma constante
	velocity.y = 0
	velocity.x = -speed * 3 
	animation_sprite.play("run_left")

func _process_chase_stop() -> void:
	if _target_player:
		var target_pos = _target_player.global_position + Vector2(40, 0)
		
		var distance_x = global_position.x - target_pos.x
		
		# Si todavía está lejos (más de 5 píxeles de margen), sigue avanzando a la izquierda
		if distance_x > 5.0:
			velocity.y = 0
			velocity.x = -speed * 3
			animation_sprite.play("run_left")
		else:
			_change_state(State.IDLE)
			if _target_player.has_method("set_frozen"):
				_target_player.set_frozen(true)
			print("Rival colocado enfrente del jugador. Detenido.")

func _change_state(new_state: State) -> void:
	current_state = new_state

# --- SEÑALES ---
func _on_detection_area_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		_target_player = body
		# En lugar de pararse inmediatamente, cambia al estado de aproximación final
		_change_state(State.CHASE_STOP)


func _on_detection_area_2_body_exited(body: Node2D) -> void:
	# Mantenemos esto por seguridad, aunque si el jugador se congela no debería salir del área
	if body.is_in_group("Player"):
		if current_state == State.IDLE:
			body.set_frozen(false)
		_target_player = null
		_change_state(State.PATROL)
