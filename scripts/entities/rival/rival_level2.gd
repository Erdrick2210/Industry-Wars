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

func interact() -> void:
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	await get_tree().create_timer(2.0).timeout
	
	if target_player:
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
		
	## CAMBIO AQUÍ ##
	# Ya no disparamos GameEvents.end_combat() aquí inmediatamente.
	# Aquí es donde deberías disparar la señal para empezar la batalla real, por ejemplo:
	
	# Testing
	GameEvents.end_combat()
	print("[Rival Level 2] Movimiento inicial completado. Listo para el combate real.")

# --- SEÑAL DE FIN DE COMBATE ADAPTADA ---
func _on_combat_finished(player_won: bool = true, enemy_name: String = ""):
	if enemy_name != self.name: 
		return
	print("[Rival Level 2] Recibida señal de fin de combate. ¿Ganó el jugador?: ", player_won)
	
	# 1. Protegemos al script si el mapa todavía está en la caché de memoria
	if not is_inside_tree():
		print("[Rival Level 2] En caché. Esperando a regresar al árbol de escenas...")
		await tree_entered
		
	# Esperamos un frame para que se asienten las físicas tras volver de la batalla
	await get_tree().process_frame
	
	# 2. Si el jugador GANÓ el combate:
	if player_won:
		if marker:
			target_pos = marker.global_position
			is_retreating = true
			is_moving = false 
			is_blocked_look = true
			print("[Rival Level 2] Victoria del jugador. Iniciando retirada al Marker.")
	
	# 3. Si el jugador PERDIÓ el combate:
	else:
		print("[Rival Level 2] Derrota del jugador. El rival se queda en su sitio.")
		is_retreating = false
		is_moving = false
		is_blocked_look = false
		if animation_sprite:
			animation_sprite.play("idle_right")
		
		# DESCONGELAMOS AL JUGADOR para que pueda moverse, curar sus robots y reintentarlo
		if target_player and target_player.has_method("set_frozen"):
			target_player.set_frozen(false)
		elif _player and _player.has_method("set_frozen"):
			_player.set_frozen(false)

func despawn_npc():
	velocity = Vector2.ZERO
	is_retreating = false
	
	# Descongelamos al jugador al llegar al marker final
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(false)
	elif _player and _player.has_method("set_frozen"):
		_player.set_frozen(false)
	
	if get_node_or_null("../Bridge"):
		$"../Bridge".activate_bridge()
		print("[Rival Level 2] ¡Puente activado!")
	
	print("[Rival Level 2] Retirada completada. Eliminando nodo.")
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
