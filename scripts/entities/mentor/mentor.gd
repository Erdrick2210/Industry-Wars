extends InteractableNPC

const SPEED = 50.0

@export var MentoraAnimation : AnimatedSprite2D
var target_player : Node2D = null
var is_moving : bool = false
var event_finished : bool = false

func _ready() -> void:
	if not event_finished:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED

# IMPORTANTE: El movimiento físico DEBE estar aquí
func _physics_process(_delta: float) -> void:
	if is_moving:
		# Aplicamos la velocidad hacia abajo
		velocity.y = SPEED
		velocity.x = 0
		move_and_slide()
	else:
		# Si no se está moviendo por guion, podrías poner lógica de idle o seguimiento
		velocity = Vector2.ZERO

func prepare_npc():
	if event_finished:
		visible = true
		process_mode = Node.PROCESS_MODE_INHERIT
		MentoraAnimation.play("idle_down")
		return

	# Espera inicial
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree(): return
	
	visible = true
	# Cambiamos a INHERIT para que procese _physics_process
	process_mode = Node.PROCESS_MODE_INHERIT 
	MentoraAnimation.play("idle_down")
	
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# --- ACTIVAMOS MOVIMIENTO ---
	is_moving = true
	MentoraAnimation.play("run_down")
	
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree(): return
	
	# --- DETENEMOS MOVIMIENTO ---
	is_moving = false
	event_finished = true
	MentoraAnimation.play("idle_down")
