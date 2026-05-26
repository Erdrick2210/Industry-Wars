extends InteractableNPC

# --- REFERENCIAS ---
@export var enable_detection : bool = true 
@onready var detection_area = $DetectionArea2

# --- VARIABLES INTERNAS ---
enum State { PATROL, CHASE_STOP, IDLE, RETREAT } 
var current_state : State = State.PATROL
var _target_player : Node2D = null

func _ready() -> void:
	if not enable_detection:
		detection_area.monitoring = false
		detection_area.monitorable = false
		detection_area.visible = false
	
	animation_sprite.play("run_left")
	
	if GameEvents.has_signal("combat_rival_finished"):
		GameEvents.combat_rival_finished.connect(_on_combat_finished)
		
	# --- CONECTAMOS LA NUEVA SEÑAL ---
	if GameEvents.has_signal("combat_rival_cancelled"):
		GameEvents.combat_rival_cancelled.connect(_on_combat_cancelled)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.PATROL:
			_process_patrol()
		State.CHASE_STOP:
			_process_chase_stop()
		State.RETREAT:
			_process_retreat()
	
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
		
		# Disparamos el diálogo único al frenar frente al jugador
		_lanzar_dialogo_encuentro()

# --- FUNCIÓN AUXILIAR: CARGA DEL ARCHIVO REAL REPETIDO ---
func _lanzar_dialogo_encuentro() -> void:
	# Corregido: Cargamos el archivo físico real y llamamos al bloque interno "rival_novato"
	var intro_dialog = load("res://game/dialogues/region1_junkyard/first_small_rival.dialogue")
	if intro_dialog:
		await DialogueManager.show_dialogue_balloon(intro_dialog, "rival_novato")
	else:
		print("Error: No se encuentra res://game/dialogues/region1_junkyard/first_small_rival.dialogue")

func _process_retreat() -> void:
	velocity.y = 0
	velocity.x = speed * 3 
	animation_sprite.play("run_right")
	
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

	if not is_inside_tree():
		print("[Rival] Estoy en la caché. Esperando a ser añadido al árbol...")
		await tree_entered 
	
	await get_tree().process_frame
	
	var player_ref = _target_player
	
	if player_ref and player_ref.has_method("set_frozen"):
		player_ref.set_frozen(true)
	
	# === DIÁLOGOS POST-COMBATE (RUTAS SEPARADAS) ===
	if player_won:
		_change_state(State.IDLE)
		var win_dialog = load("res://game/dialogues/region1_junkyard/rival_novato_win.dialogue")
		if win_dialog:
			await DialogueManager.show_dialogue_balloon(win_dialog, "rival_novato_win")
		_change_state(State.RETREAT)
	else:
		_change_state(State.IDLE)
		var lose_dialog = load("res://game/dialogues/region1_junkyard/rival_novato_lose.dialogue")
		if lose_dialog:
			await DialogueManager.show_dialogue_balloon(lose_dialog, "rival_novato_lose")
		
		if player_ref and player_ref.has_method("set_frozen"):
			player_ref.set_frozen(false)

# --- SEÑALES DE ÁREA ---
func _on_detection_area_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and current_state == State.PATROL: 
		_target_player = body
		_change_state(State.CHASE_STOP)

# ====================== INTERACT (TECLA E) ======================
func interact() -> void:
	_change_state(State.IDLE)
	
	if _target_player and _target_player.has_method("set_frozen"):
		_target_player.set_frozen(true)
	
	# Reutiliza la función de carga correcta para evitar código duplicado
	await _lanzar_dialogo_encuentro()
	
	if _target_player and _target_player.has_method("set_frozen"):
		_target_player.set_frozen(false)

# --- SEÑAL DE COMBATE RECHAZADO ---
func _on_combat_cancelled(enemy_name: String) -> void:
	if enemy_name != self.name: 
		return
		
	print("[Rival] El jugador ha rechazado el combate. Esperando interacción manual...")
	_change_state(State.IDLE)
	
	# Descongelamos al jugador para que siga moviéndose libremente
	if _target_player and _target_player.has_method("set_frozen"):
		_target_player.set_frozen(false)
