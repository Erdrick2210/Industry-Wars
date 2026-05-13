extends InteractableNPC

# --- REFERENCIAS ---
@export var enable_detection : bool = true 
@onready var detection_area = $DetectionArea2


# --- VARIABLES INTERNAS ---
enum State { PATROL, IDLE }
var current_state : State = State.PATROL

func _ready() -> void:
	# Configuración inicial del área de detección
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
	
	move_and_slide()


func _process_idle() -> void:
	velocity = Vector2.ZERO
	animation_sprite.play("idle_left")

func _process_patrol() -> void:
	# Se mueve constantemente hacia la izquierda (eje X negativo)
	velocity.y = 0
	velocity.x = -speed * 3 
	animation_sprite.play("run_left")


func _change_state(new_state: State) -> void:
	current_state = new_state

# --- SEÑALES ---
func _on_detection_area_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		_change_state(State.IDLE)
		body.set_frozen(true)


func _on_detection_area_2_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.set_frozen(false)
