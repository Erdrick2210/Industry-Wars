extends Node2D

signal game_over(win: bool)

@onready var player = $Player
var start_position: Vector2

func _ready() -> void:
	if player:
		start_position = player.global_position
		
		# ¡AÑADE ESTA LÍNEA! Busca la cámara dentro del jugador y la activa
		if player.has_node("Camera2D"):
			player.get_node("Camera2D").make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart_level()

func _on_void_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		restart_level()

func restart_level() -> void:
	print("Reintentando nivel...") #debug
	if player:
		player.global_position = start_position
		if "coins" in player:
			player.coins = 0 

func complete_minigame() -> void:
	game_over.emit(true)

func _on_end_body_entered(body: Node2D) -> void:
	# Este mensaje aparecerá en tu consola inferior en cuanto toques el área
	print("¡Meta tocada por!: ", body.name)
	
	# Si el cuerpo que entró es un CharacterBody2D (tu jugador), cerramos el juego
	if body is CharacterBody2D or body.name == "Player":
		print("¡Fin del juego! Regresando al mundo grande...")
		game_over.emit(true) # Le avisa a la abuela para destruir el minijuego
