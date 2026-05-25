extends PathFollow2D

@export var velocidad: float = 60.0

# Referencias automáticas de tus nodos
@onready var npc_body: CharacterBody2D = $Kid
@onready var animation_sprite: AnimatedSprite2D = $Kid/AnimatedSprite2D

func _ready() -> void:
	# Aseguramos que empiece completamente recto
	rotation = 0
	if is_instance_valid(npc_body):
		npc_body.rotation = 0

func _process(delta: float) -> void:
	# Forzamos la rotación visual a 0 en cada frame para que no se tumbe
	rotation = 0
	if is_instance_valid(npc_body):
		npc_body.rotation = 0

	# --- INTERRUPTOR DE INTERACCIÓN ---
	if npc_body and npc_body.get("is_interacting") == true:
		return

	# 1. Avanzamos en el camino
	progress += velocidad * delta
	
	# 2. LA SOLUCIÓN: Usamos el vector de dirección del Path en lugar de la resta
	# 'get_velocity()' o el vector de dirección normalizado de la transformación del Path
	var direccion_camino: Vector2 = transform.x.normalized()
	
	# 3. Mandamos la dirección limpia a la lógica de animación
	if velocidad > 0:
		_actualizar_animacion_caminar(direccion_camino)
	else:
		if animation_sprite:
			animation_sprite.play("idle_down")

func _actualizar_animacion_caminar(direccion: Vector2) -> void:
	if not animation_sprite:
		return
		
	# Comparamos si el camino va más en horizontal (X) o vertical (Y)
	if abs(direccion.x) > abs(direccion.y):
		# Movimiento horizontal
		if direccion.x > 0:
			animation_sprite.play("run_right")
		else:
			animation_sprite.play("run_left")
	else:
		# Movimiento vertical
		if direccion.y > 0:
			animation_sprite.play("run_down")
		else:
			animation_sprite.play("run_up")
