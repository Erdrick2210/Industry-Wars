extends InteractableNPC

const SPEED = 50.0

@export var MentoraAnimation : AnimatedSprite2D

var target_player : Node2D = null
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
		velocity.y = SPEED
		velocity.x = 0
		move_and_slide()
		return # No ejecuta la mirada mientras camina

	# PRIORIDAD 2: Mirar al jugador si no se está moviendo
	_update_look_direction()

func _update_look_direction() -> void:
	# Si perdimos la referencia (por el caché), la buscamos de nuevo
	if target_player == null:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			target_player = players[0]
	
	# Lógica de rotación visual
	if target_player:
		var diff = target_player.global_position - global_position
		
		# Comparamos si el jugador está más lejos en X o en Y
		if abs(diff.x) > abs(diff.y):
			# Mirar horizontalmente
			MentoraAnimation.play("idle_right" if diff.x > 0 else "idle_left")
		else:
			# Mirar verticalmente
			MentoraAnimation.play("idle_down" if diff.y > 0 else "idle_up")
	else:
		# Posición por defecto si el jugador no está cerca
		MentoraAnimation.play("idle_down")

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
	MentoraAnimation.play("idle_down")
	
	# 2. Pequeña pausa antes de empezar a caminar
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# 3. Empieza a caminar
	is_moving = true
	MentoraAnimation.play("run_down")
	
	# 4. Duración de la caminata
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree(): return
	
	# 5. Finalización
	is_moving = false
	velocity = Vector2.ZERO
	event_finished = true
	MentoraAnimation.play("idle_down")

func interact() -> void:
	# Usamos la referencia que ya tenemos o buscamos al jugador
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
		
	print("¡Hola! Soy la mentora.") # Aquí iría tu sistema de diálogos
	
	await get_tree().create_timer(2.0).timeout
	
	if target_player:
		target_player.set_frozen(false)

# --- SEÑALES DEL AREA2D ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = null
