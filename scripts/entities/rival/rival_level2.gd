extends InteractableNPC

# --- REFERENCIAS ---
@onready var marker = $"../WarpZones/RetiradaRival"
@onready var area = $"../TriggerAnimacioRival"

# --- Diálogos ---
@export var dialogue_resource: DialogueResource

var is_moving: bool = false
var is_retreating: bool = false
var target_pos: Vector2 = Vector2.ZERO
var _player : Node2D = null

func _ready():
	if GameEvents.rival_event_done:
		if is_instance_valid(area):
			area.queue_free()
	
	if GameEvents.has_signal("combat_rival_finished"):
		GameEvents.combat_rival_finished.connect(_on_combat_finished)


func interact() -> void:
	# Si ya se está marchando, bloqueamos que el jugador pueda volver a hablarle
	if is_retreating or is_moving: 
		return
		
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	
	await _lanzar_dialogo_encuentro()
	
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


func finish_movement():
	velocity = Vector2.ZERO
	is_moving = false
	is_blocked_look = false
	if animation_sprite:
		animation_sprite.play("idle_right")
	
	# --- RESTAURADO: Lanza el diálogo nada más llegar frente a ti ---
	_lanzar_dialogo_encuentro()


func _lanzar_dialogo_encuentro() -> void:
	var encuentro_dialog = load("res://game/dialogues/region2/rival_encuentro_r2.dialogue")
	if encuentro_dialog:
		await DialogueManager.show_dialogue_balloon(encuentro_dialog, "rival_encuentro_r2")
	else:
		print("Error: No se encuentra el diálogo de encuentro")


# ====================== FIN DEL COMBATE ======================
func _on_combat_finished(player_won: bool = true, enemy_name: String = "") -> void:
	# Filtro flexible para asegurar que responda aunque el nombre varíe un poco en el testeo
	if enemy_name != self.name and "Rival" not in enemy_name:
		return
	
	print("[Rival Nivel 2] Combate terminado. Ganó jugador?: ", player_won)
	
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	
	# Volvemos a congelar momentáneamente para que no se mueva el mapa durante el diálogo final
	var jugador_real = get_tree().get_first_node_in_group("Player")
	if jugador_real and jugador_real.has_method("set_frozen"):
		jugador_real.set_frozen(true)
	
	# Diálogo según resultado
	if player_won:
		var win_dialog = load("res://game/dialogues/region2/rival_victoria_r2.dialogue")
		if win_dialog:
			await DialogueManager.show_dialogue_balloon(win_dialog, "rival_victoria_r2")
	else:
		var lose_dialog = load("res://game/dialogues/region2/rival_derrota_r2.dialogue")
		if lose_dialog:
			await DialogueManager.show_dialogue_balloon(lose_dialog, "rival_derrota_r2")
	
	# Al cerrar el diálogo, descongelamos al jugador para que recupere el control
	_descongelar_jugador_seguro()
	
	# === RETIRADA FORZADA ===
	if marker:
		target_pos = marker.global_position
		is_retreating = true
		is_moving = false
		is_blocked_look = true
		print("[Rival Nivel 2] Iniciando retirada hacia marker")
	else:
		print("[Rival Nivel 2] ERROR: No se encontró marker, desapareciendo directamente.")
		despawn_npc()


func _descongelar_jugador_seguro() -> void:
	var jugador_real = get_tree().get_first_node_in_group("Player")
	if jugador_real and jugador_real.has_method("set_frozen"):
		jugador_real.set_frozen(false)


func despawn_npc():
	velocity = Vector2.ZERO
	is_retreating = false
	_descongelar_jugador_seguro()
	
	if get_node_or_null("../Bridge"):
		$"../Bridge".activate_bridge()
		print("[Rival Nivel 2] ¡Puente abierto con éxito!")
	
	queue_free()


# --- RESTAURADO: SEÑAL DEL TRIGGER DEL MAPA ---
func _on_trigger_animacio_rival_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameEvents.rival_event_done = true
		_player = body
		start_movement(_player)
		
		if _player.has_method("set_frozen"):
			_player.set_frozen(true)
		
		if is_instance_valid(area):
			area.queue_free()
