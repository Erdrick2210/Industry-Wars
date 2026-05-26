extends InteractableNPC

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "mara_first"

var is_moving : bool = false
var event_finished : bool = false 

func _ready() -> void:
	# Estado inicial: oculto si el evento no ha ocurrido
	if not event_finished:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(_delta: float) -> void:
	# PRIORIDAD 1: Movimiento por guion
	if is_moving:
		velocity.y = speed
		velocity.x = 0
		move_and_slide()
		return # No ejecuta la mirada mientras camina

	# PRIORIDAD 2: Mirar al jugador si no se está moviendo
	_update_look_direction()


func prepare_npc() -> void:
	# Si ya terminó su caminata en una visita anterior, solo la mostramos
	if event_finished:
		visible = true
		process_mode = Node.PROCESS_MODE_INHERIT
		return

	# --- SECUENCIA DE INTRODUCCIÓN ---
	
	# 1. Espera inicial (el nodo está en el limbo del caché o recién creado)
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree(): return # Seguridad: abortar si el jugador cambió de nivel
	
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	animation_sprite.play("idle_down")
	
	# 2. Pequeña pausa antes de empezar a caminar
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# 3. Empieza a caminar
	is_moving = true
	animation_sprite.play("run_down")
	
	# 4. Duración de la caminata
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree(): return
	
	# 5. Finalización
	is_moving = false
	velocity = Vector2.ZERO
	event_finished = true
	animation_sprite.play("idle_down")

func interact() -> void:
	if not dialogue_resource:
		print("Error: Diálogo no asignado en Mara")
		return
	
	# Congelar jugador
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	
	# Mostrar diálogo (misma forma que usas en el rival)
	await DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
	
	# Descongelar jugador
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(false)
