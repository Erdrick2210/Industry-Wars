extends Node2D

@onready var reward_chest = $Chest/Area2D
@onready var start_console = $StartConsole/Area2D
@onready var player = $Player

var available_colors: Array[String] = ["green", "red", "blue", "yellow"]

var round_lengths: Array[int] = [3, 5, 7]
var current_round: int = 0

var target_sequence: Array[String] = []
var player_input_index: int = 0

enum GameState { NOT_STARTED, SHOWING_SEQUENCE, WAITING_FOR_INPUT, GAME_OVER, PUZZLE_SOLVED }
var current_state = GameState.NOT_STARTED

func _ready():
	pass

func start_round():
	if current_round >= round_lengths.size():
		win_puzzle()
		return

	target_sequence.clear()
	player_input_index = 0
	current_state = GameState.SHOWING_SEQUENCE

	var sequence_length = round_lengths[current_round]
	for i in range(sequence_length):
		var random_color = available_colors.pick_random()
		target_sequence.append(random_color)

	play_sequence_animation()

func play_sequence_animation():
	if player:
		player.set_frozen(true) 
		
	await get_tree().create_timer(0.5).timeout

	for color in target_sequence:
		print("Flashing: ", color)
		var pillar = get_node(color.capitalize() + "Pillar/ItemInteract")
		if pillar:
			pillar.sequence_flash(0.6)
		await get_tree().create_timer(0.8).timeout 

	current_state = GameState.WAITING_FOR_INPUT
	print("Tu turno! Inserta la secuencia.")

	if player:
		player.set_frozen(false)

func _on_pillar_interacted(color_pressed: String):
	if current_state != GameState.WAITING_FOR_INPUT:
		return 

	print("Player selected: ", color_pressed)

	var pillar = get_node(color_pressed.capitalize() + "Pillar")
	if pillar:
		pillar.modulate = Color(2.0, 2.0, 2.0)
		await get_tree().create_timer(0.2).timeout
		pillar.modulate = Color(1, 1, 1)

	if color_pressed == target_sequence[player_input_index]:
		player_input_index += 1 

		if player_input_index == target_sequence.size():
			print("Round ", current_round + 1, " clear!")
			current_round += 1
			
			await get_tree().create_timer(1.0).timeout
			start_round()
	else:
		lose_puzzle()

func lose_puzzle():
	current_state = GameState.GAME_OVER
	print("Game Over. Vuelve a intentarlo usando la consola.")
	
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	
	current_round = 0 
	target_sequence.clear()

	current_state = GameState.NOT_STARTED

	if start_console and start_console.has_method("reset_console"):
		start_console.reset_console()

func win_puzzle():
	current_state = GameState.PUZZLE_SOLVED
	print("Puzzle Resuelto! Desbloqueando recompensa...")

	if reward_chest:
		reward_chest.unlock()
		
func begin_puzzle():
	if current_state == GameState.NOT_STARTED:
		print("Puzzle Iniciado! Preparate...")
		await get_tree().create_timer(1.0).timeout
		start_round()
