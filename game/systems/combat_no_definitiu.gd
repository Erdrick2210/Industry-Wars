extends Node

# ─────────────────────────────────────────────────────────────
# ENUM ESTADO
# ─────────────────────────────────────────────────────────────

enum CombatState { START, DETERMINE_TURN, PLAYER_TURN, ENEMY_TURN, END_BATTLE }

var state: CombatState = CombatState.START

# ─────────────────────────────────────────────────────────────
# ROBOTS
# ─────────────────────────────────────────────────────────────

var player_robot: RobotParty.RobotInstance
var enemy_robot: RobotParty.RobotInstance

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
# INIT
# ─────────────────────────────────────────────────────────────

func _ready():
	_init_battle()

func _init_battle() -> void:
	if RobotParty.party.size() == 0:
		push_error("El jugador no tiene robots en el party")
		return
	
	player_robot = RobotParty.party[0]
	enemy_robot = RobotParty.party[1] # Cogemos un robot de la party, esto se debe cambiar
	
	print_robot_stats()
	
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

		CombatState.ENEMY_TURN:
			await enemy_turn()

		CombatState.END_BATTLE:
			await log_and_wait("Combate terminado")

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

	await attack(player_robot, enemy_robot, 60)
	await end_turn()
	
func _on_bag_pressed() -> void:
	print("Mochila no implementada")
	
func _on_robots_pressed() -> void:
	print("Robots no implementado")
	
func _on_giveup_pressed() -> void:
	print("Rendirse no implementado")

# ─────────────────────────────────────────────────────────────
# ENEMY TURN
# ─────────────────────────────────────────────────────────────

func enemy_turn() -> void:
	await log_and_wait("¡Turno del enemigo!")

	await attack(enemy_robot, player_robot, 50)

	await end_turn()

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
	
	print("Daño: " + str(damage) + " | HP: " + str(def.current_hp))
	await log_and_wait("Daño: %d | HP: %d" % [
		damage,
		def.current_hp
	])

	await get_tree().create_timer(1.0).timeout

	await check_win_condition()
	

# ─────────────────────────────────────────────────────────────
# TURN END
# ─────────────────────────────────────────────────────────────

func end_turn() -> void:

	if state == CombatState.END_BATTLE:
		return

	if state == CombatState.PLAYER_TURN:
		change_state(CombatState.ENEMY_TURN)
	else:
		change_state(CombatState.PLAYER_TURN)

# ─────────────────────────────────────────────────────────────
# WIN CONDITION
# ─────────────────────────────────────────────────────────────

func check_win_condition() -> bool:

	if enemy_robot.current_hp <= 0:
		await log_and_wait("¡Has ganado!")
		RobotParty.give_exp(0, 50)
		state = CombatState.END_BATTLE
		return true

	if player_robot.current_hp <= 0:
		await log_and_wait("Has perdido...")
		state = CombatState.END_BATTLE
		return true

	return false



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
