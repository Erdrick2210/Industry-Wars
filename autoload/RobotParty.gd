## RobotParty.gd
## Autoload — gestiona el equipo activo del jugador (hasta 4 robots).
## Añadir en Project > Autoload con nombre "RobotParty"
##
## Fórmula de nivel: level = floor(cbrt(total_exp))
##   → exp necesaria para nivel N = N^3
## Stats escaladas por nivel: stat = base_stat * (1 + 0.05 * (level - 1))

extends Node

signal party_changed
signal robot_leveled_up(slot: int, robot: RobotInstance, new_level: int)

# ─── Instancia de robot en el equipo ──────────────────────────────────────────

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
	var learned_abilities: Array  # Array[String]
	
	# Nivel de Stats durante el combate
	var stat_stages = {
		"attack": 0,
		"defense": 0,
		"speed": 0,
		"accuracy": 0,
		"evasion": 0
	}
	
	# Estados alterados
	var status_effects = {
		"stunned": false,
		"short_circuit": false,
		"damage_to_hp": 0.0
	}

	func _init(p_chassis_id: int, p_exp: int = 1) -> void:
		chassis_id        = p_chassis_id
		nickname          = ""
		total_exp         = p_exp
		learned_abilities = []

	func display_name() -> String:
		if nickname.is_empty():
			var def = RobotDB.get_chassis(chassis_id)
			return def.name if def else "???"
		return nickname

# ─── Party ────────────────────────────────────────────────────────────────────

var party: Array = []   # Array[RobotInstance], máximo 4

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Equipo de demo — quitar en producción
	_add_demo_party()

# ─── Nivel y EXP ──────────────────────────────────────────────────────────────

## Nivel a partir de EXP total:  level = floor(EXP^(1/3))
static func exp_to_level(exp: int) -> int:
	return max(1, int(pow(float(exp), 1.0 / 3.0)))

## EXP mínima para alcanzar el nivel N:  exp = N^3
static func level_to_exp(level: int) -> int:
	return level * level * level

## EXP mínima para el SIGUIENTE nivel
static func exp_for_next_level(current_exp: int) -> int:
	var next_lvl := exp_to_level(current_exp) + 1
	return level_to_exp(next_lvl)

## Fracción de progreso hacia el siguiente nivel (0.0 – 1.0)
static func level_progress(current_exp: int) -> float:
	var lvl      := exp_to_level(current_exp)
	var exp_this := level_to_exp(lvl)
	var exp_next := level_to_exp(lvl + 1)
	if exp_next == exp_this:
		return 1.0
	return float(current_exp - exp_this) / float(exp_next - exp_this)

# ─── Cálculo de stats ─────────────────────────────────────────────────────────

## Recalcula todas las stats de una instancia según su nivel actual.
## Escala lineal simple: stat = base * (1 + 0.05 * (level - 1))
func recalculate_stats(robot: RobotInstance) -> void:
	var def = RobotDB.get_chassis(robot.chassis_id)
	if def == null:
		return

	var lvl   := exp_to_level(robot.total_exp)
	var scale := 1.0 + 0.05 * float(lvl - 1)

	var prev_level := robot.level
	robot.level    = lvl
	robot.max_hp   = int(def.base_hp  * scale)
	robot.max_ep   = int(def.base_ep  * scale)
	robot.attack   = int(def.base_atk * scale)
	robot.defense  = int(def.base_def * scale)
	robot.speed    = int(def.base_spd * scale)

	# Mantener HP/EP dentro del nuevo máximo
	robot.current_hp = min(robot.current_hp, robot.max_hp)
	robot.current_ep = min(robot.current_ep, robot.max_ep)

	# Desbloquear habilidades del nivel alcanzado
	_check_new_abilities(robot, def, prev_level, lvl)

func _check_new_abilities(robot: RobotInstance, def, prev_level: int, new_level: int) -> void:
	for ab in def.abilities:
		if ab["level"] > prev_level and ab["level"] <= new_level:
			if not ab["id"] in robot.learned_abilities:
				robot.learned_abilities.append(ab["id"])

# ─── Dar EXP ──────────────────────────────────────────────────────────────────

func give_exp(slot: int, amount: int) -> void:
	if slot < 0 or slot >= party.size():
		return
	var robot: RobotInstance = party[slot] as RobotInstance
	var old_level := exp_to_level(robot.total_exp)
	robot.total_exp += amount
	recalculate_stats(robot)
	if robot.level > old_level:
		robot_leveled_up.emit(slot, robot, robot.level)
	party_changed.emit()

# ─── Añadir / quitar robots ───────────────────────────────────────────────────

func add_robot(chassis_id: int, starting_exp: int = 1) -> bool:
	if party.size() >= 4:
		return false
	var robot := RobotInstance.new(chassis_id, starting_exp)
	robot.current_hp = 0   # se llena en recalculate_stats
	robot.current_ep = 0
	recalculate_stats(robot)
	robot.current_hp = robot.max_hp
	robot.current_ep = robot.max_ep
	party.append(robot)
	party_changed.emit()
	return true

func remove_robot(slot: int) -> void:
	if slot < 0 or slot >= party.size():
		return
	party.remove_at(slot)
	party_changed.emit()
	
# ─── Estadísticas durante el combate ────────────────────────────────────────────────────────────

func modify_stage(robot, stat:String, amount:int):
	if not robot.stat_stages.has(stat):
		return

	var old_stage = robot.stat_stages[stat]

	robot.stat_stages[stat] = clamp(old_stage + amount, -3, 3)
	
func get_stage_text(stat:String, amount:int) -> String:
	var stat_name = {
		"attack": "ataque",
		"defense": "defensa",
		"speed": "velocidad",
		"accuracy": "precisión",
		"evasion": "evasión"
	}

	if amount > 0:
		return "¡El %s aumentó!" % stat_name[stat]

	return "¡El %s disminuyó!" % stat_name[stat]

# ─── Serialización ────────────────────────────────────────────────────────────

func serialize() -> Array:
	var out := []
	for r in party:
		var robot: RobotInstance = r as RobotInstance
		out.append({
			"chassis_id":        robot.chassis_id,
			"nickname":          robot.nickname,
			"total_exp":         robot.total_exp,
			"current_hp":        robot.current_hp,
			"current_ep":        robot.current_ep,
			"learned_abilities": robot.learned_abilities.duplicate(),
		})
	return out

func deserialize(data: Array) -> void:
	party.clear()
	for d in data:
		var robot := RobotInstance.new(d["chassis_id"], d["total_exp"])
		robot.nickname          = d.get("nickname", "")
		robot.current_hp        = d.get("current_hp", 0)
		robot.current_ep        = d.get("current_ep", 0)
		robot.learned_abilities = d.get("learned_abilities", []).duplicate()
		recalculate_stats(robot)
		party.append(robot)
	party_changed.emit()

# ─── Demo ─────────────────────────────────────────────────────────────────────

func _add_demo_party() -> void:
	# EXP de ejemplo: nivel 5 = 125, nivel 8 = 512, nivel 3 = 27, nivel 10 = 1000
	add_robot(1, 520)   # Guardián  ~nivel 8
	add_robot(2, 520)   # Asalto    ~nivel 8
	add_robot(3,  30)   # Explorador ~nivel 3
	add_robot(4, 980)   # Técnico   ~nivel 9
