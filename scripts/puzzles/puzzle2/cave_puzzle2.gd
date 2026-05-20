extends Node2D

@onready var reward_chest = $Chest/Area2D
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
	# Check if the player has beaten all 3 rounds
	if current_round >= round_lengths.size():
		win_puzzle()
		return

	target_sequence.clear()
	player_input_index = 0
	current_state = GameState.SHOWING_SEQUENCE

	# Generate a random sequence for this round using your 4 pillars
	var sequence_length = round_lengths[current_round]
	for i in range(sequence_length):
		var random_color = available_colors.pick_random()
		target_sequence.append(random_color)

	# Flash the sequence to the player
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
	print("Your turn! Enter the sequence.")

	if player:
		player.set_frozen(false)

func _on_pillar_interacted(color_pressed: String):
	# Ignore inputs if the pattern is still playing or the puzzle is done
	if current_state != GameState.WAITING_FOR_INPUT:
		return 

	print("Player selected: ", color_pressed)
	
	# Visual feedback when the player triggers a pillar
	var pillar = get_node(color_pressed.capitalize() + "Pillar")
	if pillar:
		pillar.modulate = Color(2.0, 2.0, 2.0)
		await get_tree().create_timer(0.2).timeout
		pillar.modulate = Color(1, 1, 1)

	if color_pressed == target_sequence[player_input_index]:
		player_input_index += 1 

		# Did they complete the sequence for the current round?
		if player_input_index == target_sequence.size():
			print("Round ", current_round + 1, " clear!")
			current_round += 1
			
			# Brief delay before starting the next round
			await get_tree().create_timer(1.0).timeout
			start_round()
	else:
		# Player made a mistake
		lose_puzzle()

func lose_puzzle():
	current_state = GameState.GAME_OVER
	print("Wrong order! Resetting to Round 1...")

	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	
	current_round = 0 
	await get_tree().create_timer(1.0).timeout
	start_round()

func win_puzzle():
	current_state = GameState.PUZZLE_SOLVED
	print("Puzzle Solved! Unlocking reward...")

	if reward_chest:
		reward_chest.unlock()
		
func begin_puzzle():
	# Only start if the puzzle hasn't been started yet
	if current_state == GameState.NOT_STARTED:
		print("Puzzle Initiated! Get ready...")
		await get_tree().create_timer(1.0).timeout
		start_round()
