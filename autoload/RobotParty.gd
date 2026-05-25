## RobotParty.gd  (v3)
## Autoload "RobotParty"
## Novedades:
##   - active_moves: Array[String] máx. 4 — ataques activos en combate
##   - set_active_move / remove_active_move para gestionar el moveset
##   - heal_robot() llamado por Inventory.use_item
##   - Persistencia automática en user://save_game.json

extends Node

signal party_changed
signal robot_leveled_up(slot: int, robot: RobotInstance, new_level: int)

const SAVE_PATH := "user://save_game.json"

# ─── RobotInstance ────────────────────────────────────────────────────────────

class RobotInstance:
	var chassis_id:  int
	var nickname:    String    # vacío = usa el nombre del chasis
	var total_exp:   int
	var current_hp:  int       # HP actuales (se reduce en combate)
	var current_ep:  int       # EP actuales

	# Stats calculadas (se actualizan al subir nivel)
	var level:       int
	var max_hp:      int
	var max_ep:      int
	var attack:      int
	var defense:     int
	var speed:       int
	
	# Habilidades desbloqueadas (ids de las que ya aprendió)
	var learned_abilities: Array  # todos los aprendidos
	var active_moves:      Array  # máx. 4, usados en combate

	var equipped_core:    String = ""
	var equipped_modules: Array  = []
	
	# Nivel de Stats durante el combate
	var stat_stages = {
		"attack": 0,
		"defense": 0,
		"speed": 0,
		"accuracy": 0,
		"evasion": 0
	}
	
	# Estados alterados
	var status_effect: String = ""
	var volatile_statuses := {}

	func _init(p_chassis_id: int, p_exp: int = 1) -> void:
		chassis_id        = p_chassis_id
		nickname          = ""
		total_exp         = p_exp
		learned_abilities = []
		active_moves      = []
		equipped_core     = ""
		equipped_modules  = []

	func display_name() -> String:
		if nickname.is_empty():
			var def = RobotDB.get_chassis(chassis_id)
			return def.name if def else "???"
		return nickname
	
	# Devuelve el stat alterado por el combate
	func get_modified_stat(stat_name:String) -> int:
		var base_value = self.get(stat_name)
		var stage = stat_stages.get(stat_name, 0)
		var multiplier = stage_to_multiplier(stage)
		return int(base_value * multiplier)
	
	# Conversor de nivel de stat a multiplicador
	func stage_to_multiplier(stage:int) -> float:
		match stage:
			-3: return 0.4
			-2: return 0.5
			-1: return 0.66
			0: return 1.0
			1: return 1.5
			2: return 2.0
			3: return 2.5
		return 1.0
	
	# Modificadores de estados alterados
	func has_status(status: String) -> bool:
		return status_effect == status

	func add_status(status:String):
		status_effect = status

	func remove_status():
		status_effect = ""
		
	# Modificadores de estdos temporales
	func add_volatile_status(status: String):
		volatile_statuses[status] = true
		
	func remove_volatile_status(status: String):
		volatile_statuses.erase(status)
		
	func has_volatile_status(status: String) -> bool:
		return volatile_statuses.has(status)
	
	func reset_battle_modifiers():
		for stat in stat_stages.keys():
			stat_stages[stat] = 0

	## Habilidades aprendidas que NO están en active_moves
	func available_moves() -> Array:
		var out: Array = []
		for ab in learned_abilities:
			if not ab in active_moves:
				out.append(ab)
		return out

# ─── Party ────────────────────────────────────────────────────────────────────

var party: Array = []

func _ready() -> void:
	_add_demo_party()
	if not _load():
		_add_demo_party()

# ─── Nivel / EXP ──────────────────────────────────────────────────────────────

static func exp_to_level(exp: int) -> int:
	return max(1, int(pow(float(exp), 1.0 / 3.0)))

static func level_to_exp(level: int) -> int:
	return level * level * level

static func exp_for_next_level(current_exp: int) -> int:
	return level_to_exp(exp_to_level(current_exp) + 1)

static func level_progress(current_exp: int) -> float:
	var lvl      := exp_to_level(current_exp)
	var exp_this := level_to_exp(lvl)
	var exp_next := level_to_exp(lvl + 1)
	if exp_next == exp_this:
		return 1.0
	return float(current_exp - exp_this) / float(exp_next - exp_this)

# ─── Stats ────────────────────────────────────────────────────────────────────

func recalculate_stats(robot: RobotInstance) -> void:
	var def = RobotDB.get_chassis(robot.chassis_id)
	if def == null:
		return
	var lvl   := exp_to_level(robot.total_exp)
	var scale := 1.0 + 0.05 * float(lvl - 1)
	var prev_level := robot.level
	robot.level   = lvl
	robot.max_hp  = int(def.base_hp  * scale)
	robot.max_ep  = int(def.base_ep  * scale)
	robot.attack  = int(def.base_atk * scale)
	robot.defense = int(def.base_def * scale)
	robot.speed   = int(def.base_spd * scale)
	_reapply_equipment(robot)
	robot.current_hp = min(robot.current_hp, robot.max_hp)
	robot.current_ep = min(robot.current_ep, robot.max_ep)
	_check_new_abilities(robot, def, prev_level, lvl)

func _check_new_abilities(robot: RobotInstance, def, prev_level: int, new_level: int) -> void:
	for ab in def.abilities:
		if ab["level"] > prev_level and ab["level"] <= new_level:
			if not ab["id"] in robot.learned_abilities:
				robot.learned_abilities.append(ab["id"])
				if robot.active_moves.size() < 4:
					robot.active_moves.append(ab["id"])

func _reapply_equipment(robot: RobotInstance) -> void:
	if not robot.equipped_core.is_empty():
		var core = ModuleDB.get_core(robot.equipped_core)
		if core:
			_apply_modifiers(robot, core.modifiers, true)
	for mod_id in robot.equipped_modules:
		var mod = ModuleDB.get_module(mod_id)
		if mod:
			_apply_modifiers(robot, mod.modifiers, true)

func _apply_modifiers(robot: RobotInstance, mods: Dictionary, add: bool) -> void:
	var sign: int = 1 if add else -1
	if mods.has("attack"):  robot.attack  += sign * int(mods["attack"])
	if mods.has("defense"): robot.defense += sign * int(mods["defense"])
	if mods.has("speed"):   robot.speed   += sign * int(mods["speed"])
	if mods.has("max_hp"):  robot.max_hp  += sign * int(mods["max_hp"])
	if mods.has("max_ep"):  robot.max_ep  += sign * int(mods["max_ep"])

# ─── Gestión de moveset ───────────────────────────────────────────────────────

## Asigna ability_id al slot indicado (0-3).
## Si ya está en otro slot, intercambia. Si el slot tiene otro ataque, lo desplaza.
func set_active_move(robot_slot: int, move_slot: int, ability_id: String) -> bool:
	if robot_slot < 0 or robot_slot >= party.size():
		return false
	var robot := party[robot_slot] as RobotInstance
	if not ability_id in robot.learned_abilities:
		return false
	if move_slot < 0 or move_slot > 3:
		return false

	# Asegurar que el array tiene el tamaño correcto
	while robot.active_moves.size() <= move_slot:
		robot.active_moves.append("")

	var existing_idx: int = robot.active_moves.find(ability_id)
	if existing_idx != -1 and existing_idx != move_slot:
		# Swap
		var displaced: String       = robot.active_moves[move_slot]
		robot.active_moves[move_slot]    = ability_id
		robot.active_moves[existing_idx] = displaced
	elif existing_idx == -1:
		robot.active_moves[move_slot] = ability_id

	# Limpiar entradas vacías al final pero mantener hasta 4
	robot.active_moves.resize(mini(robot.active_moves.size(), 4))

	party_changed.emit()
	_save()
	return true

## Quita una habilidad del moveset activo.
func remove_active_move(robot_slot: int, ability_id: String) -> bool:
	if robot_slot < 0 or robot_slot >= party.size():
		return false
	var robot := party[robot_slot] as RobotInstance
	if not ability_id in robot.active_moves:
		return false
	robot.active_moves.erase(ability_id)
	party_changed.emit()
	_save()
	return true

# ─── Núcleo ───────────────────────────────────────────────────────────────────

func equip_core(robot_slot: int, core_id: String) -> bool:
	if robot_slot < 0 or robot_slot >= party.size():
		return false
	var robot := party[robot_slot] as RobotInstance
	if ModuleDB.get_core(core_id) == null:
		return false
	if not robot.equipped_core.is_empty():
		unequip_core(robot_slot)
	robot.equipped_core = core_id
	recalculate_stats(robot)
	party_changed.emit()
	_save()
	return true

func unequip_core(robot_slot: int) -> bool:
	if robot_slot < 0 or robot_slot >= party.size():
		return false
	var robot := party[robot_slot] as RobotInstance
	if robot.equipped_core.is_empty():
		return false
	robot.equipped_core = ""
	recalculate_stats(robot)
	party_changed.emit()
	_save()
	return true

# ─── Módulos ──────────────────────────────────────────────────────────────────

enum EquipError { OK, SLOT_FULL, ALREADY_EQUIPPED, TOO_MANY_ACTIVE, TOO_MANY_STAT, UNKNOWN_MODULE }

func equip_module_on_robot(robot_slot: int, module_id: String) -> int:
	if robot_slot < 0 or robot_slot >= party.size():
		return EquipError.UNKNOWN_MODULE
	var robot := party[robot_slot] as RobotInstance
	var mod    = ModuleDB.get_module(module_id)
	if mod == null:                          return EquipError.UNKNOWN_MODULE
	if robot.equipped_modules.size() >= 3:  return EquipError.SLOT_FULL
	if module_id in robot.equipped_modules: return EquipError.ALREADY_EQUIPPED
	if mod.type == "active":
		for mid in robot.equipped_modules:
			var em = ModuleDB.get_module(mid)
			if em and em.type == "active":   return EquipError.TOO_MANY_ACTIVE
	if mod.stat_slot != "none":
		for mid in robot.equipped_modules:
			var em = ModuleDB.get_module(mid)
			if em and em.stat_slot != "none": return EquipError.TOO_MANY_STAT
	robot.equipped_modules.append(module_id)
	if mod.type == "active" and not mod.skill_id.is_empty():
		if not mod.skill_id in robot.learned_abilities:
			robot.learned_abilities.append(mod.skill_id)
		if robot.active_moves.size() < 4 and not mod.skill_id in robot.active_moves:
			robot.active_moves.append(mod.skill_id)
	recalculate_stats(robot)
	party_changed.emit()
	_save()
	return EquipError.OK

func unequip_module_from_robot(robot_slot: int, module_id: String) -> bool:
	if robot_slot < 0 or robot_slot >= party.size():
		return false
	var robot := party[robot_slot] as RobotInstance
	if not module_id in robot.equipped_modules:
		return false
	robot.equipped_modules.erase(module_id)
	var mod = ModuleDB.get_module(module_id)
	if mod and mod.type == "active" and not mod.skill_id.is_empty():
		robot.learned_abilities.erase(mod.skill_id)
		robot.active_moves.erase(mod.skill_id)
	recalculate_stats(robot)
	party_changed.emit()
	_save()
	return true

# ─── EXP ──────────────────────────────────────────────────────────────────────

func give_exp(slot: int, amount: int) -> void:
	if slot < 0 or slot >= party.size():
		return
	var robot := party[slot] as RobotInstance
	var old_level := exp_to_level(robot.total_exp)
	robot.total_exp += amount
	recalculate_stats(robot)
	if robot.level > old_level:
		robot_leveled_up.emit(slot, robot, robot.level)
	party_changed.emit()
	_save()

# ─── Curar (llamado por Inventory) ───────────────────────────────────────────

func heal_robot(robot_slot: int, hp: int, ep: int) -> void:
	if robot_slot < 0 or robot_slot >= party.size():
		return
	var robot := party[robot_slot] as RobotInstance
	if hp > 0:
		robot.current_hp = mini(robot.current_hp + hp, robot.max_hp)
	if ep > 0:
		robot.current_ep = mini(robot.current_ep + ep, robot.max_ep)
	party_changed.emit()
	_save()

# ─── Añadir robots ────────────────────────────────────────────────────────────

func add_robot(chassis_id: int, starting_exp: int = 1) -> bool:
	if party.size() >= 4:
		return false
	var robot := RobotInstance.new(chassis_id, starting_exp)
	recalculate_stats(robot)
	robot.current_hp = robot.max_hp
	robot.current_ep = robot.max_ep
	party.append(robot)
	party_changed.emit()
	_save()
	return true
	
func create_robot(chassis_id: int, starting_exp: int = 1) -> RobotInstance:
	var robot := RobotInstance.new(chassis_id, starting_exp)

	recalculate_stats(robot)

	robot.current_hp = robot.max_hp
	robot.current_ep = robot.max_ep

	return robot

# ─── Persistencia ─────────────────────────────────────────────────────────────

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("RobotParty._save: no se pudo abrir '%s'" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(serialize(), "\t"))
	file.close()
	
# ─── Estadísticas durante el combate ────────────────────────────────────────────────────────────

func modify_stage(robot, stat:String, amount:int):
	if not robot.stat_stages.has(stat):
		return

	var old_stage = robot.stat_stages[stat]
	robot.stat_stages[stat] = clamp(old_stage + amount, -3, 3)

func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Array:
		return false
	deserialize(parsed)
	return true

func serialize() -> Array:
	var out := []
	for r in party:
		var robot := r as RobotInstance
		out.append({
			"chassis_id":        robot.chassis_id,
			"nickname":          robot.nickname,
			"total_exp":         robot.total_exp,
			"current_hp":        robot.current_hp,
			"current_ep":        robot.current_ep,
			"learned_abilities": robot.learned_abilities.duplicate(),
			"active_moves":      robot.active_moves.duplicate(),
			"equipped_core":     robot.equipped_core,
			"equipped_modules":  robot.equipped_modules.duplicate(),
		})
	return out

func deserialize(data: Array) -> void:
	party.clear()
	for d in data:
		var robot              := RobotInstance.new(d["chassis_id"], d["total_exp"])
		robot.nickname          = d.get("nickname", "")
		robot.current_hp        = d.get("current_hp", 0)
		robot.current_ep        = d.get("current_ep", 0)
		robot.learned_abilities = d.get("learned_abilities", []).duplicate()
		robot.active_moves      = d.get("active_moves",      []).duplicate()
		robot.equipped_core     = d.get("equipped_core",     "")
		robot.equipped_modules  = d.get("equipped_modules",  []).duplicate()
		recalculate_stats(robot)
		party.append(robot)
	party_changed.emit()

func _add_demo_party() -> void:
	# EXP de ejemplo: nivel 5 = 125, nivel 8 = 512, nivel 3 = 27, nivel 10 = 1000
	add_robot(1, 520)   # Guardián  ~nivel 8
	add_robot(2, 520)   # Asalto    ~nivel 8
	add_robot(3,  980)   # Explorador ~nivel 9
	add_robot(4, 980)   # Técnico   ~nivel 9
