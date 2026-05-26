extends InteractableNPC

var is_moving: bool = false
var is_retreating: bool = false
var target_pos: Vector2 = Vector2.ZERO
var _player : Node2D = null

@onready var marker = $"../WarpZones/RetiradaRival"
@onready var area = $"../TriggerAnimacioRival"

func _ready():
	if GameEvents.rival_event_done:
		# Si el evento ya se completó en el pasado, eliminamos el trigger
		if is_instance_valid(area):
			area.queue_free()
			
	GameEvents.combat_rival_finished.connect(_on_combat_finished)

# Por si el jugador rechaza el combate, se cura y vuelve a hablarle manualmente con la E
func interact() -> void:
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	
	# Volvemos a lanzar el desafío de revancha usando la función de carga relativa correcta
	await _lanzar_dialogo_encuentro()
	
	# Si vuelve a decir que no o cancela, se le descongela
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(false)

func _physics_process(delta: float) -> void:
	if is_moving or is_retreating:
		var direction = (target_pos - global_position).normalized()
		var distance = global_position.distance_to(target_pos)
		
		if distance > 5.0: 
			velocity = direction * speed
			move_and_slide()
			
			if animation_sprite:
				if direction.x > 0:
					animation_sprite.play("run_right")
				else:
					animation_sprite.play("run_left")
		else:
			if is_retreating:
				despawn_npc()
			else:
				finish_movement()
	else:
		super._physics_process(delta)

func start_movement(player_node: Node2D):
	target_player = player_node 
	target_pos = target_player.global_position + Vector2(-40, 0)
	
	is_moving = true
	is_blocked_look = true

# Se ejecuta al terminar la caminata automática hacia el jugador
func finish_movement():
	velocity = Vector2.ZERO
	is_moving = false
	is_blocked_look = false
	
	if animation_sprite:
		animation_sprite.play("idle_right")
		
	print("[Rival Revancha] Lanzando diálogo de revancha automático...")
	
	# Lanzamos el encuentro automáticamente tras la caminata inicial
	_lanzar_dialogo_encuentro()

# --- FUNCIÓN AUXILIAR: CARGA RELATIVA DEL DIÁLOGO INICIAL (RUTA CORREGIDA) ---
func _lanzar_dialogo_encuentro() -> void:
	var encuentro_dialog = load("res://game/dialogues/region2/rival_encuentro_r2.dialogue")
	if encuentro_dialog:
		await DialogueManager.show_dialogue_balloon(encuentro_dialog, "rival_encuentro_r2")
	else:
		print("Error: No se encuentra res://game/dialogues/region2/rival_encuentro_r2.dialogue")
		if target_player and target_player.has_method("set_frozen"):
			target_player.set_frozen(false)

# --- FIN DE COMBATE (REVANCHA - CON CAMINOS RELATIVOS CORREGIDOS) ---
func _on_combat_finished(player_won: bool = true, enemy_name: String = ""):
	if enemy_name != self.name: 
		return
	print("[Rival Revancha] ¿Ganó el jugador?: ", player_won)
	
	if not is_inside_tree():
		await tree_entered
		
	await get_tree().process_frame
	
	# De vuelta en el mapa, congelamos un momento para el diálogo post-combate
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	
	# === MANEJO DE RESULTADOS CON ARCHIVOS SEPARADOS ===
	if player_won:
		var win_dialog = load("res://game/dialogues/region2/rival_victoria_r2.dialogue")
		if win_dialog:
			# El rival dice su diálogo de derrota antes de huir
			await DialogueManager.show_dialogue_balloon(win_dialog, "rival_victoria_r2")
			
		if marker:
			target_pos = marker.global_position
			is_retreating = true
			is_moving = false 
			is_blocked_look = true
			print("[Rival Revancha] Iniciando retirada hacia el Marker y despejando el camino.")
	else:
		var lose_dialog = load("res://game/dialogues/region2/rival_derrota_r2.dialogue")
		if lose_dialog:
			# El rival presume su victoria si pierdes
			await DialogueManager.show_dialogue_balloon(lose_dialog, "rival_derrota_r2")
		
		print("[Rival Revancha] Derrota del jugador. Se puede reintentar.")
		is_retreating = false
		is_moving = false
		is_blocked_look = false
		if animation_sprite:
			animation_sprite.play("idle_right")
		
		# Si pierde, se le descongela aquí para que pueda reorganizarse y volver a intentar
		if target_player and target_player.has_method("set_frozen"):
			target_player.set_frozen(false)
		elif _player and _player.has_method("set_frozen"):
			_player.set_frozen(false)

func despawn_npc():
	velocity = Vector2.ZERO
	is_retreating = false
	
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(false)
	elif _player and _player.has_method("set_frozen"):
		_player.set_frozen(false)
	
	# Se activa el puente para poder pasar a la zona de la League Boss
	if get_node_or_null("../Bridge"):
		$"../Bridge".activate_bridge()
		print("[Rival Revancha] ¡Puente hacia la Boss activado!")
	
	queue_free()

func _on_trigger_animacio_rival_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameEvents.rival_event_done = true
		_player = body
		start_movement(_player)
		
		if _player.has_method("set_frozen"):
			_player.set_frozen(true)
		
		if is_instance_valid(area):
			area.queue_free()
