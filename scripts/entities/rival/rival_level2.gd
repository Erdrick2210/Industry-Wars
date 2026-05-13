extends InteractableNPC

var is_moving: bool = false
var target_pos: Vector2 = Vector2.ZERO
var _player : Node2D = null

@onready var area = $"../TriggerAnimacioRival"

func _ready():
	if GameEvents.rival_event_done:
		area.queue_free()

func interact() -> void:
	# TODO / Implementar diàleg o el que sigui
	if target_player and target_player.has_method("set_frozen"):
		target_player.set_frozen(true)
	await get_tree().create_timer(2.0).timeout
	
	if target_player:
		target_player.set_frozen(false)


func _physics_process(delta: float) -> void:
	if is_moving:
		var direction = (target_pos - global_position).normalized()
		var distance = global_position.distance_to(target_pos)
		
		if distance > 10.0: 
			# Usamos 'speed', que es como la has nombrado en tu clase padre
			velocity = direction * speed
			move_and_slide()
			
			if animation_sprite:
				animation_sprite.play("run_right")
		else:
			finish_movement()
			
			
	else:
		# IMPORTANTE: Llamar al padre para que siga mirando al jugador si no se mueve
		super._physics_process(delta)

# Modificamos esta función para que RECIBA al jugador directamente
func start_movement(player_node: Node2D):
	target_player = player_node # Aseguramos que el NPC sepa quién es el jugador
	target_pos = target_player.global_position + Vector2(-40, 0)
	
	is_moving = true
	is_blocked_look = true

func finish_movement():
	velocity = Vector2.ZERO
	is_moving = false
	is_blocked_look = false
	if animation_sprite:
		animation_sprite.play("idle_right")
	_player.set_frozen(false)
	$"../Bridge".activate_bridge()

func _on_trigger_animacio_rival_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameEvents.rival_event_done = true
		_player = body
		start_movement(_player)
		
		if _player.has_method("set_frozen"):
			_player.set_frozen(true)
		
		area.queue_free()
