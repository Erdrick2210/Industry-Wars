extends InteractableNPC

# --- REFERENCIAS ---
@export var enable_detection : bool = true 
@onready var detection_area = $DetectionArea2

# --- VARIABLES INTERNAS ---
# Añadimos RETREAT a los estados para controlar la huida hacia la derecha
enum State { PATROL, CHASE_STOP, IDLE, RETREAT } 
var current_state : State = State.PATROL
var _target_player : Node2D = null

func _ready() -> void:
	if not enable_detection:
		detection_area.monitoring = false
		detection_area.monitorable = false
		detection_area.visible = false
	
	animation_sprite.play("run_left")
	
	# Conectamos la señal de fin de combate. 
	# Ahora asumimos que la señal envía un bool: true si ganó el jugador, false si perdió.
	if GameEvents.has_signal("combat_rival_finished"):
		GameEvents.combat_rival_finished.connect(_on_combat_finished)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.PATROL:
			_process_patrol()
		State.CHASE_STOP:
			_process_chase_stop()
		State.RETREAT:
			_process_retreat() # NUEVO: Procesa la huida a la derecha
	
	move_and_slide()

func _process_idle() -> void:
	velocity = Vector2.ZERO
	animation_sprite.play("idle_left")

func _process_patrol() -> void:
	velocity.y = 0
	velocity.x = -speed * 3 
	animation_sprite.play("run_left")

func _process_chase_stop() -> void:
	if _target_player == null:
		return
	var target_pos = _target_player.global_position + Vector2(40, 0)
	var distance_x = global_position.x - target_pos.x
		
	if distance_x > 5.0:
		velocity.y = 0
		velocity.x = -speed * 3
		animation_sprite.play("run_left")
	else:
		_change_state(State.IDLE)
		if _target_player.has_method("set_frozen"):
			_target_player.set_frozen(true)
		print("Rival colocado enfrente del jugador. Detenido.")

# NUEVO: Lógica para moverse constantemente a la derecha y desaparecer
func _process_retreat() -> void:
	velocity.y = 0
	velocity.x = speed * 3 # Velocidad positiva para ir a la derecha
	animation_sprite.play("run_right")
	
	# Usamos el VisibilityNotifier si tuvieras uno, o simplemente un temporizador 
	# o una distancia para eliminarlo. Para hacerlo independiente de Markers, 
	# si se aleja lo suficiente a la derecha del jugador (ej. 400px), desaparece:
	if _target_player and global_position.x - _target_player.global_position.x > 400.0:
		print("Rival fuera de pantalla. Eliminando nodo.")
		queue_free()

func _change_state(new_state: State) -> void:
	current_state = new_state

# --- SEÑAL DE FIN DE COMBATE ---
func _on_combat_finished(player_won: bool = true, enemy_name: String = "") -> void:
	print("[Rival] Recibida señal de fin de combate. ¿Ganó el jugador?: ", player_won)
	if enemy_name != self.name: 
		return
	enable_detection = false
	if is_instance_valid(detection_area):
		detection_area.monitoring = false
		detection_area.monitorable = false
	# 1. LA MAGIA: Si estamos en el limbo de la caché, esperamos a volver al mapa
	if not is_inside_tree():
		print("[Rival] Estoy en la caché. Esperando a ser añadido al árbol...")
		await tree_entered # Espera automáticamente hasta que main.gd haga el add_child()
	
	# 2. Ahora que estamos seguros de que estamos en el árbol, esperamos un frame por seguridad
	await get_tree().process_frame
	
	var player_ref = _target_player
	_target_player = null
	
	# EN AMBOS CASOS: Descongelamos al jugador inmediatamente
	if player_ref and player_ref.has_method("set_frozen"):
		player_ref.set_frozen(false)
		print("[Rival] Jugador descongelado.")
	else:
		# Respaldo por si falló la referencia
		var backup_player = get_parent().find_child("Player", true, false)
		if backup_player and backup_player.has_method("set_frozen"):
			backup_player.set_frozen(false)
			print("[Rival] Jugador descongelado por respaldo.")
	
	if player_won:
		_change_state(State.RETREAT)
	else:
		_change_state(State.IDLE)

# --- SEÑALES DE ÁREA ---
func _on_detection_area_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		_target_player = body
		_change_state(State.CHASE_STOP)
