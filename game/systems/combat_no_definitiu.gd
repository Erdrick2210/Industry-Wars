extends Node

# ─────────────────────────────────────────────────────────────
# ENUM ESTADO
# ─────────────────────────────────────────────────────────────

enum CombatState { START, DETERMINE_TURN, PLAYER_TURN, ENEMY_TURN, END_BATTLE }

var state: CombatState = CombatState.START

var player_can_act: bool = false

# ─────────────────────────────────────────────────────────────
# ROBOTS
# ─────────────────────────────────────────────────────────────

var player_robot: RobotParty.RobotInstance
var enemy_robot: RobotParty.RobotInstance

var participating_slots: Array[int] = []

# ─────────────────────────────────────────────────────────────
# BATTLE COMMANDS UI
# ─────────────────────────────────────────────────────────────

@onready var battle_commands = $BattleCommands
@onready var ability_container = $AbilityContainer
@onready var ability_buttons = $AbilityContainer/AbilityButtons
@onready var back_button = $AbilityContainer/Back
const AbilityButtonScene = preload("res://game/scenes/ability_button.tscn")

func _on_back_pressed() -> void:
	ability_container.visible = false
	battle_commands.visible = true
	for child in ability_buttons.get_children():
		child.queue_free()
		
# ─────────────────────────────────────────────────────────────
# ABILITY INFO PANEL
# ─────────────────────────────────────────────────────────────

@onready var ability_info = $AbilityInfoPanel

@onready var ability_name_label = $AbilityInfoPanel/NameLabel
@onready var ability_power_label = $AbilityInfoPanel/PowerLabel
@onready var ability_accuracy_label = $AbilityInfoPanel/AccuracyLabel
@onready var ability_ep_label = $AbilityInfoPanel/EPLabel
@onready var ability_description_label = $AbilityInfoPanel/DescriptionLabel

func show_ability_info(ability):
	ability_info.visible = true
	ability_name_label.text = ability.name
	ability_power_label.text = "POT: %d" % ability.power
	ability_accuracy_label.text = "ACC: %d" % ability.accuracy
	ability_ep_label.text = "EP: %d" % ability.ep_cost
	ability_description_label.text = ability.effect

# ─────────────────────────────────────────────────────────────
# UI LOG SYSTEM
# ─────────────────────────────────────────────────────────────

@onready var combat_log = $CombatLog

var queue: Array[String] = []
var is_writing: bool = false

func log_and_wait(text: String) -> void:
	queue.append(text)

	if not is_writing:
		await _process_log()

	while is_writing or queue.size() > 0:
		await get_tree().process_frame
		
	await get_tree().create_timer(1.2).timeout

func _process_log() -> void:
	is_writing = true

	while queue.size() > 0:
		var text = queue.pop_front()

		combat_log.text = ""

		for c in text:
			combat_log.text += c
			await get_tree().create_timer(0.03).timeout

		combat_log.text += "\n"

	is_writing = false

# ─────────────────────────────────────────────────────────────
# UI BATTLEBOX UPDATE
# ─────────────────────────────────────────────────────────────

@onready var player_name = $PlayerPanel/NameLabel
@onready var player_level = $PlayerPanel/LevelLabel
@onready var player_hpbar = $PlayerPanel/HPBar
@onready var player_hp_text = $PlayerPanel/HPLabel
@onready var player_epbar = $PlayerPanel/EPBar
@onready var player_ep_text = $PlayerPanel/EPLabel
@onready var player_expbar = $PlayerPanel/EXPBar

@onready var enemy_name = $EnemyPanel/NameLabel
@onready var enemy_level = $EnemyPanel/LevelLabel
@onready var enemy_hpbar = $EnemyPanel/HPBar

func init_battle_boxes():
	# PLAYER
	player_name.text = player_robot.display_name()
	player_level.text = "Lv " + str(player_robot.level)

	player_hpbar.max_value = player_robot.max_hp
	player_hpbar.value = player_robot.current_hp
	update_hp_color(player_hpbar, player_robot.current_hp, player_robot.max_hp)
	update_player_hp_ui()
	player_epbar.max_value = player_robot.max_ep
	player_epbar.value = player_robot.current_ep
	update_player_ep_ui()
	update_player_exp_ui()

	# ENEMY
	enemy_name.text = enemy_robot.display_name()
	enemy_level.text = "Lv " + str(enemy_robot.level)

	enemy_hpbar.max_value = enemy_robot.max_hp
	enemy_hpbar.value = enemy_robot.current_hp
	update_hp_color(enemy_hpbar, enemy_robot.current_hp, enemy_robot.max_hp)
	
func animate_bar(bar: ProgressBar, target_value: int):
	var start = bar.value
	var duration = 0.5
	var steps = 20

	for i in range(steps):
		bar.value = lerp(start, float(target_value), float(i) / steps)
		await get_tree().create_timer(duration / steps).timeout

	bar.value = int(target_value)
	
func update_hp_color(bar: ProgressBar, current: int, max: int):

	var ratio = float(current) / max
	var style = bar.get_theme_stylebox("fill")

	if style == null:
		return

	style = style.duplicate()
	bar.add_theme_stylebox_override("fill", style)

	if ratio > 0.5:
		style.bg_color = Color.GREEN
	elif ratio > 0.25:
		style.bg_color = Color.YELLOW
	else:
		style.bg_color = Color.RED

func update_player_hp_ui():
	player_hpbar.value = player_robot.current_hp
	player_hp_text.text = "%d / %d" % [
		player_robot.current_hp,
		player_robot.max_hp
	]
	
func update_player_ep_ui():
	player_epbar.value = player_robot.current_ep
	player_ep_text.text = "%d / %d" % [
		player_robot.current_ep,
		player_robot.max_ep
	]
	
func update_player_exp_ui():
	player_level.text = "Lv " + str(player_robot.level)
	var current_level = player_robot.level
	var current_level_exp = RobotParty.level_to_exp(current_level)
	var next_level_exp = RobotParty.level_to_exp(current_level + 1)

	var current_progress = (player_robot.total_exp - current_level_exp)
	var needed_progress = (next_level_exp - current_level_exp)

	player_expbar.max_value = needed_progress
	player_expbar.value = current_progress
	
func animate_exp_gain(old_exp: int):
	var start_exp = old_exp
	var target_exp = player_robot.total_exp

	var current_level = RobotParty.exp_to_level(start_exp)

	while start_exp < target_exp:
		var next_level_exp = RobotParty.level_to_exp(current_level + 1)
		var segment_target = min(target_exp, next_level_exp)

		var current_level_exp = RobotParty.level_to_exp(current_level)
		var old_progress = (start_exp - current_level_exp)

		var new_progress = (segment_target - current_level_exp)
		var needed_progress = (next_level_exp - current_level_exp)

		player_expbar.max_value = needed_progress
		player_expbar.value = old_progress

		await animate_bar(player_expbar, new_progress)

		# Level up?
		if segment_target >= next_level_exp:
			current_level += 1
			player_level.text = "Lv " + str(current_level)

			await log_and_wait(
				"%s subió a nivel %d!" % [
					player_robot.display_name(),
					current_level
				]
			)

			# Reset bar
			player_expbar.value = 0

		start_exp = segment_target

	update_player_exp_ui()

# ─────────────────────────────────────────────────────────────
# INIT
# ─────────────────────────────────────────────────────────────

func _ready():
	ability_container.visible = false
	ability_info.visible = false
	_init_battle()

func _init_battle() -> void:
	if RobotParty.party.size() == 0:
		push_error("El jugador no tiene robots en el equipo!")
		return
	
	player_robot = RobotParty.party[0]
	enemy_robot = RobotParty.party[1] # Cogemos un robot de la party, esto se debe cambiar
	
	participating_slots.clear()
	participating_slots.append(0)
	
	print_robot_stats()
	
	init_battle_boxes()
	
	print("Iniciando duelo...")
	await log_and_wait("Iniciando duelo...")
	change_state(CombatState.DETERMINE_TURN)

# ─────────────────────────────────────────────────────────────
# STATE MACHINE
# ─────────────────────────────────────────────────────────────

func change_state(new_state: CombatState) -> void:
	state = new_state
	await process_state()

func process_state() -> void:
	print_robot_stats()
	match state:

		CombatState.DETERMINE_TURN:
			print("Calculando orden de turno...")
			await log_and_wait("Calculando orden de turno...")
			_determine_turn()

		CombatState.PLAYER_TURN:
			print("¡Turno del jugador! ¿Qué hará el robot?")
			await log_and_wait("¡Turno del jugador! ¿Qué hará el robot?")
			player_can_act = true

		CombatState.ENEMY_TURN:
			await enemy_turn()

		CombatState.END_BATTLE:
			await log_and_wait("Combate terminado.")
			await get_tree().create_timer(1.0).timeout
			GameManager.return_to_previous_scene()

# ─────────────────────────────────────────────────────────────
# TURN LOGIC
# ─────────────────────────────────────────────────────────────

func _determine_turn() -> void:
	if player_robot.speed >= enemy_robot.speed:
		change_state(CombatState.PLAYER_TURN)
	else:
		change_state(CombatState.ENEMY_TURN)

# ─────────────────────────────────────────────────────────────
# PLAYER INPUT
# ─────────────────────────────────────────────────────────────

func _on_fight_pressed() -> void:
	if state != CombatState.PLAYER_TURN:
		return
		
	if player_can_act:
		show_player_abilities()
	
func _on_bag_pressed() -> void:
	if player_can_act:
		print("Mochila no implementada")
	
func _on_robots_pressed() -> void:
	if player_can_act:
		print("Robots no implementado")
	# In the future use -> participating_slots.append(nuevo_slot) to give 100% exp
	
func _on_giveup_pressed() -> void:
	if player_can_act:
		print("Rendirse no implementado")

# ─────────────────────────────────────────────────────────────
# ENEMY TURN
# ─────────────────────────────────────────────────────────────

func enemy_turn() -> void:
	await log_and_wait("¡Turno del enemigo!")

	var ability = get_enemy_ability()
	
	# Spend EP
	enemy_robot.current_ep -= ability.ep_cost

	await log_and_wait(
		"%s usa %s." % [
			enemy_robot.display_name(),
			ability.name
		]
	)

	await attack(enemy_robot, player_robot, ability.power)

	await end_turn()
	
func get_enemy_ability():
	var available_abilities = []

	for ability_id in enemy_robot.learned_abilities:
		var ability = AbilityDB.get_ability(ability_id)

		if ability == null:
			continue

		if enemy_robot.current_ep >= ability.ep_cost:
			available_abilities.append(ability)

	if available_abilities.is_empty():
		return null

	return available_abilities.pick_random() # We choose a random ability for the moment

# ─────────────────────────────────────────────────────────────
# ATTACK SYSTEM
# ─────────────────────────────────────────────────────────────

func attack(atk, def, power: int) -> void:
	print(atk.display_name() + " ataca a " + def.display_name() + ".")
	await log_and_wait("%s ataca a %s." % [
		atk.display_name(),
		def.display_name()
	])

	var damage = (atk.attack * power / 100.0) - (def.defense * 0.1)
	damage = max(1, round(damage))

	def.current_hp = max(def.current_hp - damage, 0)
	if def == player_robot:
		await animate_bar(player_hpbar, player_robot.current_hp)
		update_hp_color(player_hpbar, player_robot.current_hp, player_robot.max_hp)
		update_player_hp_ui()
	else:
		await animate_bar(enemy_hpbar, enemy_robot.current_hp)
		update_hp_color(enemy_hpbar, enemy_robot.current_hp, enemy_robot.max_hp)
	
	print("Daño: " + str(damage) + " | HP: " + str(def.current_hp))

	await check_win_condition()

# ─────────────────────────────────────────────────────────────
# ABILITIES
# ─────────────────────────────────────────────────────────────
	
func show_player_abilities():
	print(player_robot.learned_abilities)
	battle_commands.visible = false
	ability_container.visible = true
	
	for child in ability_buttons.get_children():
		child.queue_free()

	# Create buttons
	for ability_id in player_robot.learned_abilities:

		var ability = AbilityDB.get_ability(ability_id)
		if ability == null:
			continue

		var btn = AbilityButtonScene.instantiate()

		btn.text = "%s" % [
			ability.name
		]
		
		btn.mouse_entered.connect(func():
			show_ability_info(ability)
		)
		
		btn.mouse_exited.connect(func():
			ability_info.visible = false
		)
		
		btn.pressed.connect(func():
			await use_ability(ability)
		)

		ability_buttons.add_child(btn)

func use_ability(ability):
	
	# Hide ability_menu
	battle_commands.visible = true
	ability_container.visible = false
	for child in ability_buttons.get_children():
		child.queue_free()

	# Verify EP
	if player_robot.current_ep < ability.ep_cost:
		await log_and_wait("No hay suficiente EP.")
		show_player_abilities()
		return
	
	player_can_act = false

	# Spend EP
	player_robot.current_ep -= ability.ep_cost
	await animate_bar(player_epbar, player_robot.current_ep)
	update_player_ep_ui()
	
	await log_and_wait(
		"%s usa %s." % [
			player_robot.display_name(),
			ability.name
		]
	)

	await attack(player_robot, enemy_robot, ability.power)
	
	await end_turn()

# ─────────────────────────────────────────────────────────────
# TURN END
# ─────────────────────────────────────────────────────────────

func end_turn() -> void:
	if state == CombatState.END_BATTLE:
		change_state(CombatState.END_BATTLE)
	elif state == CombatState.PLAYER_TURN:
		change_state(CombatState.ENEMY_TURN)
	else:
		change_state(CombatState.PLAYER_TURN)

# ─────────────────────────────────────────────────────────────
# WIN CONDITION
# ─────────────────────────────────────────────────────────────

func check_win_condition() -> bool:
	if enemy_robot.current_hp <= 0:
		await log_and_wait("¡Has ganado!")
		var old_exp = player_robot.total_exp
		give_battle_exp(enemy_robot, participating_slots)
		await animate_exp_gain(old_exp)
		await log_and_wait("Tus robots han conseguido EXP.")
		state = CombatState.END_BATTLE
		return true

	if player_robot.current_hp <= 0:
		await log_and_wait("Has perdido...")
		state = CombatState.END_BATTLE
		return true

	return false
	
func give_battle_exp(enemy_robot, participants: Array[int]):
	var enemy_def = RobotDB.get_chassis(enemy_robot.chassis_id)

	if enemy_def == null:
		return

	var base_exp = int(
		(enemy_def.base_exp * enemy_robot.level) / 7
	)

	for i in range(RobotParty.party.size()):
		var exp_gain = base_exp

		# Robots que NO participaron → 50%
		if not participants.has(i):
			exp_gain = int(base_exp * 0.5)

		RobotParty.give_exp(i, exp_gain)

# ─────────────────────────────────────────────────────────────
# ROBOT STATS
# ─────────────────────────────────────────────────────────────

func print_robot_stats():
	print("========== COMBAT STATS ==========")

	print("--- PLAYER ---")
	print(_format_robot_stats(player_robot))

	print("--- ENEMY ---")
	print(_format_robot_stats(enemy_robot))

	print("==================================")
	
func _format_robot_stats(robot) -> String:
	return "%s\nHP: %d/%d | EP: %d/%d\nATK: %d | DEF: %d | SPD: %d" % [
		robot.display_name(),
		robot.current_hp, robot.max_hp,
		robot.current_ep, robot.max_ep,
		robot.attack,
		robot.defense,
		robot.speed
	]
