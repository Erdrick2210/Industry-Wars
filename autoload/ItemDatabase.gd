## ItemDatabase.gd  (v2)
## Autoload "ItemDB"
## Novedades:
##   - ItemDef.use_effect: diccionario que describe qué hace el ítem al usarse
##       { "heal_hp": 50 }              → cura HP a un robot
##   - ItemDef.module_bonus: diccionario de bonificaciones al equipar
##       { "attack": 10, "defense": 5, "unlocks_ability": "FURIAMECANICA" }
##   - Munición → can_use=true, use_effect={"heal_hp": N}
##   - Módulos  → can_equip=true, module_bonus={...}

extends Node

# ─── Enums ────────────────────────────────────────────────────────────────────

enum Category {
	RECAMBIOS,
	ENERGIA,
	COMPONENTES,
	MODULOS,
	OBJETOS_CLAVE
}

enum SortMode {
	ALFABETICO,
	CANTIDAD,
	OBTENCION
}

# ─── ItemDef ──────────────────────────────────────────────────────────────────

class ItemDef:
	var id:           String
	var display_name: String
	var description:  String
	var category:     int
	var icon_path:    String
	var max_stack:    int
	var is_key_item:  bool
	var can_equip:    bool
	var can_use:      bool
	var sort_index:   int

	## Efecto al usar (consumibles).
	## Claves soportadas:
	##   "heal_hp"  : int  → restaura N de HP al robot objetivo
	##   "heal_ep"  : int  → restaura N de EP al robot objetivo
	var use_effect: Dictionary

	## Bonificaciones al equipar (módulos).
	## Claves soportadas:
	##   "attack"           : int    → bonus de ataque
	##   "defense"          : int    → bonus de defensa
	##   "speed"            : int    → bonus de velocidad
	##   "max_hp"           : int    → bonus de HP máximo
	##   "max_ep"           : int    → bonus de EP máximo
	##   "unlocks_ability"  : String → ID de habilidad que desbloquea
	var module_bonus: Dictionary

	func _init(p_id, p_name, p_desc, p_cat, p_icon,
			p_max := 99, p_key := false, p_equip := false, p_use := false,
			p_effect := {}, p_bonus := {}) -> void:
		id           = p_id
		display_name = p_name
		description  = p_desc
		category     = p_cat
		icon_path    = p_icon
		max_stack    = p_max
		is_key_item  = p_key
		can_equip    = p_equip
		can_use      = p_use
		use_effect   = p_effect
		module_bonus = p_bonus
		sort_index   = 0

# ─── Recipe ───────────────────────────────────────────────────────────────────

class Recipe:
	var result_id:    String
	var result_qty:   int
	var ingredients:  Array
	var display_name: String
	var description:  String

	func _init(p_result, p_qty, p_ingredients, p_name := "", p_desc := "") -> void:
		result_id    = p_result
		result_qty   = p_qty
		ingredients  = p_ingredients
		display_name = p_name
		description  = p_desc

# ─── Registries ───────────────────────────────────────────────────────────────

var items:   Dictionary = {}
var recipes: Array      = []

func _ready() -> void:
	_register_items()
	_register_recipes()

# ─── Items ────────────────────────────────────────────────────────────────────

func _register_items() -> void:
	var C := Category
	var defs: Array = [
		# ── RECAMBIOS ─────────────────────────────────────────────────────────
		ItemDef.new("pieza_motor",   "Pieza de Motor",   "Componente mecánico básico.",        C.RECAMBIOS,    "res://assets/icons/pieza_motor.png"),
		ItemDef.new("servo_roto",    "Servo Roto",        "Servo dañado, aún recuperable.",     C.RECAMBIOS,    "res://assets/icons/servo_roto.png"),
		ItemDef.new("cable_flex",    "Cable Flex",        "Cable flexible conductor.",           C.RECAMBIOS,    "res://assets/icons/cable_flex.png"),
		ItemDef.new("placa_base",    "Placa Base",        "Circuito impreso reutilizable.",      C.RECAMBIOS,    "res://assets/icons/placa_base.png",    30),

		# ── ENERGÍA / MUNICIÓN ────────────────────────────────────────────────
		# "Munición" = consumible que cura HP, como una poción
		ItemDef.new("municion_leve",  "Munición Leve",
				"Recarga los sistemas del robot. Restaura 30 HP.",
				C.ENERGIA, "res://assets/icons/municion_leve.png",
				99, false, false, true,
				{ "heal_hp": 30 }),

		ItemDef.new("municion_media", "Munición Media",
				"Recarga avanzada. Restaura 80 HP.",
				C.ENERGIA, "res://assets/icons/municion_media.png",
				99, false, false, true,
				{ "heal_hp": 80 }),

		ItemDef.new("municion_total", "Munición Total",
				"Restaura toda la vida del robot.",
				C.ENERGIA, "res://assets/icons/municion_total.png",
				20, false, false, true,
				{ "heal_hp": 9999 }),

		ItemDef.new("celula_solar",  "Célula Solar",
				"Restaura 40 EP al robot.",
				C.ENERGIA, "res://assets/icons/celula_solar.png",
				20, false, false, true,
				{ "heal_ep": 40 }),

		ItemDef.new("supercap",      "Supercondensador",
				"Restaura toda la EP del robot.",
				C.ENERGIA, "res://assets/icons/supercap.png",
				10, false, false, true,
				{ "heal_ep": 9999 }),

		# Reparaciones rápidas — curan HP parcial o total
		ItemDef.new("kit_reparacion", "Kit de Reparación",
				"Restaura 50 HP al robot. Fiable y compacto.",
				C.ENERGIA, "res://assets/icons/kit_reparacion.png",
				99, false, false, true,
				{ "heal_hp": 50 }),

		ItemDef.new("nanobots", "Nanobots",
				"Reparación nanotecnológica. Restaura 150 HP.",
				C.ENERGIA, "res://assets/icons/nanobots.png",
				20, false, false, true,
				{ "heal_hp": 150 }),

		ItemDef.new("restauracion_total", "Restauración Total",
				"Restaura HP y EP completamente.",
				C.ENERGIA, "res://assets/icons/restauracion_total.png",
				5, false, false, true,
				{ "heal_hp": 9999, "heal_ep": 9999 }),

		# Recargas de EP
		ItemDef.new("bateria_auxiliar", "Batería Auxiliar",
				"Recarga de emergencia. Restaura 60 EP.",
				C.ENERGIA, "res://assets/icons/bateria_auxiliar.png",
				30, false, false, true,
				{ "heal_ep": 60 }),

		# ── COMPONENTES (crafting) ────────────────────────────────────────────
		ItemDef.new("chip_logica",   "Chip Lógica",      "Microprocesador básico.",             C.COMPONENTES,  "res://assets/icons/chip_logica.png"),
		ItemDef.new("sensor_ir",     "Sensor IR",         "Detecta calor e infrarrojos.",        C.COMPONENTES,  "res://assets/icons/sensor_ir.png",     50),
		ItemDef.new("motor_micro",   "Micro Motor",       "Motor eléctrico de precisión.",       C.COMPONENTES,  "res://assets/icons/motor_micro.png",   50),
		ItemDef.new("gyro",          "Giroscopio",        "Mide orientación angular.",            C.COMPONENTES,  "res://assets/icons/gyro.png",          20),

		# ── MÓDULOS (equipables) ──────────────────────────────────────────────
		# Cada módulo tiene module_bonus con stats y/o habilidad desbloqueada

		ItemDef.new("mod_escudo",    "Módulo Escudo",
				"Campo de fuerza temporal. +15 DEF. Desbloquea ABSORCIONCIRCULAR.",
				C.MODULOS, "res://assets/icons/mod_escudo.png",
				1, false, true, false, {},
				{ "defense": 15, "unlocks_ability": "ABSORCIONCIRCULAR" }),

		ItemDef.new("mod_propulsor", "Módulo Propulsor",
				"Motores extra. +20 VEL, +5 ATK. Desbloquea FURIAMECANICA.",
				C.MODULOS, "res://assets/icons/mod_propulsor.png",
				1, false, true, false, {},
				{ "speed": 20, "attack": 5, "unlocks_ability": "FURIAMECANICA" }),

		ItemDef.new("mod_vision",    "Módulo Visión",
				"Amplía el rango de visión. +10 VEL, +20 HP máx. Desbloquea EXPANSIONDEREACTOR.",
				C.MODULOS, "res://assets/icons/mod_vision.png",
				1, false, true, false, {},
				{ "speed": 10, "max_hp": 20, "unlocks_ability": "EXPANSIONDEREACTOR" }),

		ItemDef.new("mod_laser",     "Módulo Láser",
				"Haz de corte de alta energía. +25 ATK. Desbloquea IMPACTOINDUSTRIAL.",
				C.MODULOS, "res://assets/icons/mod_laser.png",
				1, false, true, false, {},
				{ "attack": 25, "unlocks_ability": "IMPACTOINDUSTRIAL" }),

		ItemDef.new("mod_reactor",   "Módulo Reactor",
				"Reactor de energía adicional. +30 EP máx, +10 DEF. Desbloquea DRENAJEREVERSIBLE.",
				C.MODULOS, "res://assets/icons/mod_reactor.png",
				1, false, true, false, {},
				{ "max_ep": 30, "defense": 10, "unlocks_ability": "DRENAJEREVERSIBLE" }),

		# ── OBJETOS CLAVE ─────────────────────────────────────────────────────
		ItemDef.new("llave_factoria", "Llave Factoría",  "Acceso a la planta abandonada.",      C.OBJETOS_CLAVE,"res://assets/icons/llave_factoria.png", 1, true),
		ItemDef.new("mapa_sector_b",  "Mapa Sector B",   "Mapa del sector B desencriptado.",    C.OBJETOS_CLAVE,"res://assets/icons/mapa_sector_b.png",  1, true),
	]

	for i in defs.size():
		defs[i].sort_index = i
		items[defs[i].id]  = defs[i]

# ─── Recipes ──────────────────────────────────────────────────────────────────

func _register_recipes() -> void:
	recipes = [
		Recipe.new("mod_escudo",    1,
			[{"id":"placa_base","qty":2},{"id":"cable_flex","qty":3},{"id":"chip_logica","qty":1}],
			"Módulo Escudo",    "Genera un campo de fuerza. +15 DEF."),
		Recipe.new("mod_propulsor", 1,
			[{"id":"motor_micro","qty":2},{"id":"municion_leve","qty":1},{"id":"pieza_motor","qty":3}],
			"Módulo Propulsor", "Motores extra. +20 VEL, +5 ATK."),
		Recipe.new("mod_vision",    1,
			[{"id":"sensor_ir","qty":2},{"id":"chip_logica","qty":2},{"id":"gyro","qty":1}],
			"Módulo Visión",    "Amplía rango de visión. +10 VEL."),
		Recipe.new("mod_laser",     1,
			[{"id":"celula_solar","qty":2},{"id":"supercap","qty":1},{"id":"chip_logica","qty":3}],
			"Módulo Láser",     "Haz de corte. +25 ATK."),
		Recipe.new("mod_reactor",   1,
			[{"id":"placa_base","qty":1},{"id":"chip_logica","qty":2},{"id":"cable_flex","qty":2}],
			"Módulo Reactor",   "Reactor extra. +30 EP, +10 DEF."),
		Recipe.new("supercap",      1,
			[{"id":"municion_leve","qty":3},{"id":"placa_base","qty":1}],
			"Supercondensador",  "Restaura toda la EP."),
	]

# ─── Helpers ──────────────────────────────────────────────────────────────────

func get_item(id: String) -> ItemDef:
	return items.get(id, null)

func get_recipes_for(result_id: String) -> Array:
	return recipes.filter(func(r): return r.result_id == result_id)

func get_all_craftable() -> Array:
	var seen := {}
	var out  := []
	for r in recipes:
		if not seen.has(r.result_id):
			seen[r.result_id] = true
			out.append(r)
	return out
