extends Node

# ─────────────────────────────────────────────────────────────
# ENUM ESTADO
# ─────────────────────────────────────────────────────────────

enum CombatState { START, DETERMINE_TURN, PLAYER_TURN, FORCED_SWITCH, END_BATTLE }

var state: CombatState = CombatState.START

const STATUS_ICONS = {
	"overheated": preload("res://assets/art/ui/overheat.png"),
	"short_circuited": preload("res://assets/art/ui/short_circuit.png")
}

var player_victory: bool = true
var player_can_act: bool = false
var waiting_for_switch: bool = false

# ─────────────────────────────────────────────────────────────
# ROBOTS
# ─────────────────────────────────────────────────────────────

var player_robot: RobotParty.RobotInstance
var enemy_robot: RobotParty.RobotInstance

var participating_slots: Array[int] = []
var active_player_slot := 0
var enemy_party: Array = []
var active_enemy_slot := 0

var player_selected_ability = null
var enemy_selected_ability = null

# ─────────────────────────────────────────────────────────────
# BATTLE COMMANDS UI
# ─────────────────────────────────────────────────────────────

@onready var battle_commands = $BattleCommands
@onready var ability_container = $AbilityContainer
@onready var ability_buttons = $AbilityContainer/AbilityButtons
@onready var back_button = $AbilityContainer/Back
@onready var prev_page_button = $AbilityContainer/PrevPage
@onready var next_page_button = $AbilityContainer/NextPage
const AbilityButtonScene = preload("res://game/scenes/ability_button.tscn")

var selected_item_id: String = ""
var battle_item_page := 0
const ITEMS_PER_PAGE := 4

func _on_back_pressed() -> void:
	prev_page_button.visible = false
	next_page_button.visible = false
	ability_container.visible = false
	battle_commands.visible = true
	for child in ability_buttons.get_children():
		child.queue_free()
		
func _on_prev_page_pressed():
	if battle_item_page > 0:
		battle_item_page -= 1
		show_battle_items()

func _on_next_page_pressed():
	battle_item_page += 1
	show_battle_items()
		
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
	if ability.accuracy == -1:
		ability_accuracy_label.text = "ACC: -"
	else:
		ability_accuracy_label.text = "ACC: %d" % ability.accuracy
	ability_ep_label.text = "EP: %d" % ability.ep_cost
	ability_description_label.text = ability.effect
	
# ─────────────────────────────────────────────────────────────
# ROBOTS INFO PANEL
# ─────────────────────────────────────────────────────────────

@onready var robot_info = $RobotsInfoPanel

@onready var robot_sprite = $RobotsInfoPanel/RobotSprite
@onready var robot_status_icon = $RobotsInfoPanel/StatusIcon

@onready var robot_name_label = $RobotsInfoPanel/NameLabel
@onready var robot_level_label = $RobotsInfoPanel/LevelLabel

@onready var robot_hpbar = $RobotsInfoPanel/HPBar
@onready var robot_hp_label = $RobotsInfoPanel/HPLabel

@onready var robot_epbar = $RobotsInfoPanel/EPBar
@onready var robot_ep_label = $RobotsInfoPanel/EPLabel

@onready var robot_stats_label = $RobotsInfoPanel/StatsLabel
@onready var robot_moves_label = $RobotsInfoPanel/MovesLabel

func show_robot_info(robot):
	robot_info.visible = true

	robot_name_label.text = robot.display_name()
	robot_level_label.text = "Lv %d" % robot.level

	var chassis = RobotDB.get_chassis(robot.chassis_id)

	if chassis:
		robot_sprite.texture = load(chassis.sprite_path)

	robot_status_icon.visible = false

	if robot.status_effect != "":
		robot_status_icon.texture = STATUS_ICONS[robot.status_effect]
		robot_status_icon.visible = true
	else:
		robot_status_icon.visible = false

	robot_hpbar.max_value = robot.max_hp
	robot_hpbar.value = robot.current_hp

	robot_hp_label.text = "PS %d / %d" % [
		robot.current_hp,
		robot.max_hp
	]

	update_hp_color(
		robot_hpbar,
		robot.current_hp,
		robot.max_hp
	)

	robot_epbar.max_value = robot.max_ep
	robot_epbar.value = robot.current_ep

	robot_ep_label.text = "EP %d / %d" % [
		robot.current_ep,
		robot.max_ep
	]

	robot_stats_label.text = (
		"ATK %d\nDEF %d\nSPD %d"
		% [
			robot.attack,
			robot.defense,
			robot.speed
		]
	)

	var move_text := ""

	for id in robot.learned_abilities:
		var ability = AbilityDB.get_ability(id)

		if ability:
			move_text += "• %s\n" % ability.name

	robot_moves_label.text = move_text

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

@onready var player_sprite = $PlayerRobot
@onready var player_name = $PlayerPanel/NameLabel
@onready var player_level = $PlayerPanel/LevelLabel
@onready var player_hpbar = $PlayerPanel/HPBar
@onready var player_hp_text = $PlayerPanel/HPLabel
@onready var player_epbar = $PlayerPanel/EPBar
@onready var player_ep_text = $PlayerPanel/EPLabel
@onready var player_expbar = $PlayerPanel/EXPBar
@onready var player_buff_container = $PlayerPanel/BuffContainer
@onready var player_status_container = $PlayerPanel/StatusContainer

@onready var enemy_sprite = $EnemyRobot
@onready var enemy_name = $EnemyPanel/NameLabel
@onready var enemy_level = $EnemyPanel/LevelLabel
@onready var enemy_hpbar = $EnemyPanel/HPBar
@onready var enemy_buff_container = $EnemyPanel/BuffContainer
@onready var enemy_status_container = $EnemyPanel/StatusContainer

func init_battle_boxes():
	# PLAYER
	player_sprite.texture = load(RobotDB.get_chassis(player_robot.chassis_id).sprite_path)
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
	update_stat_stages_ui(player_robot, player_buff_container)
	update_status_effects_ui(player_robot, player_status_container)

	# ENEMY
	enemy_sprite.texture = load(RobotDB.get_chassis(enemy_robot.chassis_id).sprite_path)
	enemy_name.text = enemy_robot.display_name()
	enemy_level.text = "Lv " + str(enemy_robot.level)

	enemy_hpbar.max_value = enemy_robot.max_hp
	enemy_hpbar.value = enemy_robot.current_hp
	update_hp_color(enemy_hpbar, enemy_robot.current_hp, enemy_robot.max_hp)
	update_stat_stages_ui(enemy_robot, enemy_buff_container)
	update_status_effects_ui(enemy_robot, enemy_status_container)

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
	
func update_stat_stages_ui(robot, container):
	# Clear old
	for child in container.get_children():
		child.queue_free()

	for stat in robot.stat_stages.keys():
		var stage = robot.stat_stages[stat]

		if stage == 0:
			continue

		var label = Label.new()
		label.modulate = Color.BLACK

		if stage > 0:
			label.text = "↑ %s %d" % [
				stat.substr(0,3).to_upper(),
				stage
			]
		else:
			label.text = "↓ %s %d" % [
				stat.substr(0,3).to_upper(),
				abs(stage)
			]

		container.add_child(label)
		
func update_status_effects_ui(robot, container):
	for child in container.get_children():
		child.queue_free()

	if robot.status_effect == "":
		return

	if not STATUS_ICONS.has(robot.status_effect):
		return

	var icon = TextureRect.new()

	icon.texture = STATUS_ICONS[robot.status_effect]
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	container.add_child(icon)

# ─────────────────────────────────────────────────────────────
# INIT
# ─────────────────────────────────────────────────────────────

func _ready():
	prev_page_button.visible = false
	next_page_button.visible = false
	ability_container.visible = false
	ability_info.visible = false
	robot_info.visible = false
	_init_battle()

func _init_battle() -> void:
	if RobotParty.party.size() == 0:
		push_error("El jugador no tiene robots en el equipo!")
		return
	
	enemy_party = create_enemy_party()
	
	player_robot = RobotParty.party[active_player_slot]
	enemy_robot = enemy_party[active_enemy_slot]
	
	participating_slots.clear()
	participating_slots.append(0)
	
	print_robot_stats()
	
	init_battle_boxes()
	
	print("Iniciando duelo...")
	await log_and_wait("Iniciando duelo...")
	change_state(CombatState.DETERMINE_TURN)
	
func create_enemy_party() -> Array:
	return [
		RobotParty.create_robot(2, 520),
		RobotParty.create_robot(3, 520)
	]

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
			_determine_turn()

		CombatState.PLAYER_TURN:
			print("¿Qué hará el robot?")
			await log_and_wait("¿Qué hará el robot?")
			player_can_act = true

		CombatState.END_BATTLE:
			await log_and_wait("Combate terminado.")
			player_robot.reset_battle_modifiers()
			enemy_robot.reset_battle_modifiers()
			await get_tree().create_timer(1.0).timeout
			
			var rival_name = "Rival"
			GameEvents.end_battle(player_victory, rival_name)
			
			# NUEVO: Buscamos el nodo raíz 'main' en el árbol de Godot y le pedimos regresar
			var main_node = get_tree().root.get_node_or_null("main") # Asegúrate de que tu escena principal se llame "main" (en minúsculas/mayúsculas según tu proyecto)
			if main_node and main_node.has_method("_end_battle_and_return"):
				main_node._end_battle_and_return()
			else:
				# Si no encuentra el nodo 'main' por su nombre, lo busca en el script padre de su CanvasLayer
				var parent = get_parent()
				if parent is CanvasLayer and parent.get_parent().has_method("_end_battle_and_return"):
					parent.get_parent()._end_battle_and_return()

# ─────────────────────────────────────────────────────────────
# TURN LOGIC
# ─────────────────────────────────────────────────────────────

func _determine_turn() -> void:
	# La IA elige primero
	enemy_selected_ability = get_enemy_ability()

	# Esperamos la acción del jugador
	change_state(CombatState.PLAYER_TURN)

# ─────────────────────────────────────────────────────────────
# PLAYER INPUT
# ─────────────────────────────────────────────────────────────

func _on_fight_pressed() -> void:
	if state != CombatState.PLAYER_TURN:
		return
		
	if player_can_act:
		show_player_abilities()
	
func _on_bag_pressed() -> void:
	if not player_can_act:
		return
	
	battle_item_page = 0
	show_battle_items()
	
func _on_robots_pressed() -> void:
	if not player_can_act:
		return
		
	show_robot_menu()
	
func _on_giveup_pressed() -> void:
	if player_can_act:
		print("Rendirse no implementado")
	
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
# BAG MENU
# ─────────────────────────────────────────────────────────────

func show_battle_items():
	battle_commands.visible = false
	ability_container.visible = true

	for child in ability_buttons.get_children():
		child.queue_free()

	var slots = Inventory.get_slots_for_category(
		ItemDB.Category.ENERGIA,
		ItemDB.SortMode.OBTENCION
	)

	if slots.is_empty():
		await log_and_wait("No tienes objetos.")
		ability_container.visible = false
		battle_commands.visible = true
		return

	var start = battle_item_page * ITEMS_PER_PAGE
	var end = min(start + ITEMS_PER_PAGE, slots.size())

	for i in range(start, end):
		var slot = slots[i]
		var item = ItemDB.get_item(slot.item_id)

		if item == null:
			continue

		if not item.can_use:
			continue

		var btn = AbilityButtonScene.instantiate()

		btn.text = "%s x%d" % [
			item.display_name,
			slot.quantity
		]

		btn.mouse_entered.connect(func():
			show_item_info(item)
		)

		btn.mouse_exited.connect(func():
			ability_info.visible = false
		)

		btn.pressed.connect(func():
			selected_item_id = slot.item_id
			show_robot_menu_for_item()
		)

		ability_buttons.add_child(btn)
		
	# ─────────────────────────────
	# PAGINATION BUTTONS
	# ─────────────────────────────

	prev_page_button.visible = battle_item_page > 0

	next_page_button.visible = end < slots.size()
		
func show_item_info(item):
	ability_info.visible = true

	ability_name_label.text = item.display_name
	ability_description_label.text = item.description

	ability_power_label.text = ""
	ability_ep_label.text = ""

	var effect_text := ""

	if item.use_effect.has("heal_hp"):
		effect_text += "HP +%d " % item.use_effect["heal_hp"]

	if item.use_effect.has("heal_ep"):
		effect_text += "EP +%d" % item.use_effect["heal_ep"]

	ability_accuracy_label.text = effect_text
	
func show_robot_menu_for_item():
	prev_page_button.visible = false
	next_page_button.visible = false
	
	for child in ability_buttons.get_children():
		child.queue_free()
		
	var item = ItemDB.get_item(selected_item_id)
	
	if item == null:
		return

	for i in range(RobotParty.party.size()):
		var robot = RobotParty.party[i]

		var btn = AbilityButtonScene.instantiate()

		btn.text = "%s" % robot.display_name()
		
		# Desactivar si no se puede usar
		btn.disabled = not can_use_item_on_robot(item, robot)

		btn.mouse_entered.connect(func():
			show_robot_info(robot)
		)

		btn.mouse_exited.connect(func():
			robot_info.visible = false
		)

		btn.pressed.connect(func():
			await use_battle_item(selected_item_id, i)
		)

		ability_buttons.add_child(btn)
		
func can_use_item_on_robot(item, robot) -> bool:
	if robot.current_hp <= 0:
		return false

	var needs_hp := false
	var needs_ep := false

	if item.use_effect.has("heal_hp"):
		needs_hp = robot.current_hp < robot.max_hp

	if item.use_effect.has("heal_ep"):
		needs_ep = robot.current_ep < robot.max_ep

	# Si no tiene efectos conocidos
	if not item.use_effect.has("heal_hp") and not item.use_effect.has("heal_ep"):
		return true

	return needs_hp or needs_ep
		
func use_battle_item(item_id: String, robot_slot: int):
	battle_commands.visible = true
	ability_container.visible = false

	for child in ability_buttons.get_children():
		child.queue_free()

	var robot = RobotParty.party[robot_slot]

	if not Inventory.use_item(item_id, robot_slot):
		await log_and_wait("No se pudo usar el objeto.")
		return

	await log_and_wait(
		"Usaste el objeto en %s." % robot.display_name()
	)

	selected_item_id = ""

	# Actualizar UI
	await animate_bar(player_hpbar, robot.current_hp)
	update_hp_color(player_hpbar, robot.current_hp, robot.max_hp)
	update_player_hp_ui()
	await animate_bar(player_epbar, robot.current_ep)
	update_player_ep_ui()

	player_can_act = false

	# Turno enemigo
	if enemy_robot.current_hp > 0:
		if await can_act(enemy_robot):
			await attack(enemy_robot, player_robot, enemy_selected_ability)

	if state == CombatState.END_BATTLE:
		return

	await process_status_effects()

	if not await check_win_condition():
		change_state(CombatState.DETERMINE_TURN)

# ─────────────────────────────────────────────────────────────
# ROBOTS MENU
# ─────────────────────────────────────────────────────────────
	
func show_robot_menu():
	battle_commands.visible = false
	ability_container.visible = true
	
	# SOLO mostrar volver si el cambio NO es obligatorio
	back_button.visible = not waiting_for_switch

	for child in ability_buttons.get_children():
		child.queue_free()

	for i in range(RobotParty.party.size()):
		var robot = RobotParty.party[i]
		var btn = AbilityButtonScene.instantiate()

		btn.text = "%s" % [
			robot.display_name()
		]

		# No permitir cambiar al actual
		if i == active_player_slot:
			btn.disabled = true

		# No permitir KO
		if robot.current_hp <= 0:
			btn.disabled = true
			
		btn.mouse_entered.connect(func():
			show_robot_info(robot)
		)

		btn.mouse_exited.connect(func():
			robot_info.visible = false
		)

		btn.pressed.connect(func():
			await switch_robot(i)
		)

		ability_buttons.add_child(btn)
		
func switch_robot(new_slot: int):
	battle_commands.visible = true
	ability_container.visible = false

	for child in ability_buttons.get_children():
		child.queue_free()

	var old_robot = player_robot

	active_player_slot = new_slot
	player_robot = RobotParty.party[new_slot]

	# Participó en combate
	if not participating_slots.has(new_slot):
		participating_slots.append(new_slot)

	# Sólo mostrar "vuelve" si no murió
	if old_robot.current_hp > 0:
		await log_and_wait("¡%s vuelve!" % old_robot.display_name())

	await log_and_wait("¡Adelante, %s!" % player_robot.display_name())
	
	# Actualizar UI
	init_battle_boxes()
	
	# ─────────────────────────────
	# FORCED SWITCH
	# ─────────────────────────────
	
	if waiting_for_switch:
		waiting_for_switch = false
		change_state(CombatState.DETERMINE_TURN)
		return
	
	# ─────────────────────────────
	# NORMAL SWITCH
	# ─────────────────────────────

	player_can_act = false

	# El enemigo ataca después del cambio
	if enemy_robot.current_hp > 0:
		await attack(enemy_robot, player_robot, enemy_selected_ability)

	# Fin de turno
	if state == CombatState.END_BATTLE:
		return
	
	# Estados alterados
	await process_status_effects()
	if not await check_win_condition():
		change_state(CombatState.DETERMINE_TURN)

# ─────────────────────────────────────────────────────────────
# ATTACK SYSTEM
# ─────────────────────────────────────────────────────────────

func attack(atk, def, ability) -> void:
	if ability.target != "Self":
		await log_and_wait("%s ataca a %s." % [
			atk.display_name(),
			def.display_name()
		])
	
	# ─────────────────────────────
	# SPEND EP
	# ─────────────────────────────
	
	await spend_ep(atk, ability.ep_cost)
	
	await log_and_wait(
		"%s usa %s." % [
			atk.display_name(),
			ability.name
		]
	)
	
	# ─────────────────────────────
	# Accuracy check
	# ─────────────────────────────

	if not BattleCalculator.check_accuracy(atk, def, ability):
		await log_and_wait("%s falla." % ability.name)
		return
	
	# ─────────────────────────────
	# Damage
	# ─────────────────────────────

	var damage := 0

	if ability.category == "Damage":
		damage = BattleCalculator.calculate_damage(atk, def, ability)
		await apply_damage(def, damage)

	# ─────────────────────────────
	# Effects
	# ─────────────────────────────

	await BattleEffects.apply_effect(self, ability.effect_id, atk, def, ability)
	update_stat_stages_ui(player_robot, player_buff_container)
	update_stat_stages_ui(enemy_robot, enemy_buff_container)
	update_status_effects_ui(player_robot, player_status_container)
	update_status_effects_ui(enemy_robot, enemy_status_container)
	
func apply_damage(defender, damage) -> void:
	defender.current_hp = max(defender.current_hp - damage, 0)
	
	if defender == player_robot:
		await animate_bar(player_hpbar, player_robot.current_hp)
		update_hp_color(player_hpbar, player_robot.current_hp, player_robot.max_hp)
		update_player_hp_ui()
	else:
		await animate_bar(enemy_hpbar, enemy_robot.current_hp)
		update_hp_color(enemy_hpbar, enemy_robot.current_hp, enemy_robot.max_hp)
	
	print("Daño: " + str(damage) + " | HP: " + str(defender.current_hp))
	
func spend_ep(robot, amount):
	robot.current_ep = max(robot.current_ep - amount, 0)
	if robot == player_robot:
		await animate_bar(player_epbar, player_robot.current_ep)
		update_player_ep_ui()

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
		return
	
	player_can_act = false

	player_selected_ability = ability

	await execute_turn()

	player_selected_ability = null
	enemy_selected_ability = null

	if state != CombatState.END_BATTLE:
		change_state(CombatState.DETERMINE_TURN)

# ─────────────────────────────────────────────────────────────
# TURN EXECUTION
# ─────────────────────────────────────────────────────────────

func execute_turn():
	var player_speed = player_robot.get_modified_stat("speed")
	var enemy_speed = enemy_robot.get_modified_stat("speed")

	var player_first := false

	# ─────────────────────────────
	# SPEED CHECK
	# ─────────────────────────────

	if player_speed > enemy_speed:
		player_first = true
	elif enemy_speed > player_speed:
		player_first = false
	else:
		player_first = randf() < 0.5

	# ─────────────────────────────
	# EXECUTION
	# ─────────────────────────────

	if player_first:
		await attack(player_robot, enemy_robot, player_selected_ability)
		if enemy_robot.current_hp > 0:
			if await check_win_condition():
				return
			if await can_act(enemy_robot):
				await attack(enemy_robot, player_robot, enemy_selected_ability)
	else:
		await attack(enemy_robot, player_robot, enemy_selected_ability)
		if player_robot.current_hp > 0:
			if await check_win_condition():
				return
			if await can_act(player_robot):
				await attack(player_robot, enemy_robot, player_selected_ability)
	
	# ─────────────────────────────
	# TURN END - STATUS CONDITIONS
	# ─────────────────────────────
	
	if state == CombatState.END_BATTLE:
		return
	
	await process_status_effects()
	if await check_win_condition():
		return
			
func process_status_effects():
	var robots = [player_robot, enemy_robot]

	robots.sort_custom(func(a, b):
		return a.get_modified_stat("speed") > b.get_modified_stat("speed")
	)

	for robot in robots:
		await process_overheat(robot)
		await process_short_circuit(robot)
	
func process_overheat(robot):
	if not robot.has_status("overheated"):
		return

	var damage = int(robot.max_hp * 0.1)
	damage = max(1, damage)

	await log_and_wait(
		"¡%s sufre daño por sobrecalentamiento!" % [
			robot.display_name()
		]
	)

	await apply_damage(robot, damage)
	
func process_short_circuit(robot):
	if not robot.has_status("short_circuited"):
		return

	var ep_loss = int(robot.max_ep * 0.1)
	ep_loss = max(1, ep_loss)

	await log_and_wait(
		"¡%s pierde energía por cortocircuito!" % [
			robot.display_name()
		]
	)
	
	await spend_ep(robot, ep_loss)

func can_act(robot) -> bool:
	if robot.has_volatile_status("stunned"):
		await log_and_wait(
			"¡%s se ha aturdido!" % [
				robot.display_name()
			]
		)
		
		robot.remove_volatile_status("stunned")
		
		return false
	return true

# ─────────────────────────────────────────────────────────────
# WIN CONDITION
# ─────────────────────────────────────────────────────────────

func check_win_condition() -> bool:
	# Enemy KO
	if enemy_robot.current_hp <= 0:
		await log_and_wait("¡%s ha sido destruido!" % enemy_robot.display_name())
		
		var next_enemy = get_next_enemy_robot()
		if next_enemy != null:
			enemy_robot = next_enemy
			await log_and_wait("¡El rival envía a %s!" % enemy_robot.display_name())
			init_battle_boxes()
			return false
		
		await log_and_wait("¡Has ganado!")
		var old_exp = player_robot.total_exp
		give_battle_exp(enemy_robot, participating_slots)
		await animate_exp_gain(old_exp)
		await log_and_wait("Tus robots han conseguido EXP.")
		player_victory = true
		await change_state(CombatState.END_BATTLE)
		return true

	# Player KO
	if player_robot.current_hp <= 0:
		await log_and_wait("¡%s ha sido destruido!" % player_robot.display_name())
		
		# Quedan robots vivos
		if has_alive_player_robots():
			waiting_for_switch = true
			state = CombatState.FORCED_SWITCH
			show_robot_menu()
			return true
		
		# Derrota
		await log_and_wait("Has perdido...")
		player_victory = false
		await change_state(CombatState.END_BATTLE)
		return true

	return false
	
func get_next_enemy_robot() -> RobotParty.RobotInstance:
	for robot in enemy_party:
		if robot.current_hp > 0:
			return robot
	return null
	
func has_alive_player_robots() -> bool:
	for i in range(RobotParty.party.size()):
		if i == active_player_slot:
			continue

		var robot = RobotParty.party[i]
		if robot.current_hp > 0:
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
	var stage_text := ""

	for stat in robot.stat_stages.keys():
		var value = robot.stat_stages[stat]

		if value == 0:
			continue

		var sign = "+"

		if value < 0:
			sign = ""

		stage_text += "%s%s%d " % [
			stat.to_upper(),
			sign,
			value
		]

	if stage_text == "":
		stage_text = "NONE"

	# Status effects
	var status_text = robot.status_effect

	if status_text == "":
		status_text = "NONE"
		
	var volatile_text = str(robot.volatile_statuses.keys())

	return "%s\nHP: %d/%d | EP: %d/%d\nATK: %d | DEF: %d | SPD: %d
	\nSTAGES: %s\nSTATUS: %s\nVOLATILE: %s" % [
		robot.display_name(),
		robot.current_hp, robot.max_hp,
		robot.current_ep, robot.max_ep,
		robot.attack,
		robot.defense,
		robot.speed,
		stage_text,
		status_text,
		volatile_text
	]
