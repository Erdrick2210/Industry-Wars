## ItemDatabase.gd
## Autoload singleton — registra todos los objetos y recetas del juego.
## Añadir en Project > Project Settings > Autoload con nombre "ItemDB"

extends Node

# ─── Enums ────────────────────────────────────────────────────────────────────

enum Category {
	RECAMBIOS,     # Spare parts
	ENERGIA,       # Energy items
	COMPONENTES,   # Crafting components
	MODULOS,       # Equippable modules
	OBJETOS_CLAVE  # Key items
}

enum SortMode {
	ALFABETICO,
	CANTIDAD,
	OBTENCION   # order of acquisition
}

# ─── Item definition ──────────────────────────────────────────────────────────

class ItemDef:
	var id: String
	var display_name: String
	var description: String
	var category: int          # Category enum
	var icon_path: String
	var max_stack: int         # 1 = no stacking
	var is_key_item: bool
	var can_equip: bool
	var can_use: bool
	var sort_index: int        # acquisition order

	func _init(p_id, p_name, p_desc, p_cat, p_icon, p_max=99, p_key=false, p_equip=false, p_use=false):
		id          = p_id
		display_name= p_name
		description = p_desc
		category    = p_cat
		icon_path   = p_icon
		max_stack   = p_max
		is_key_item = p_key
		can_equip   = p_equip
		can_use     = p_use
		sort_index  = 0

# ─── Recipe definition ────────────────────────────────────────────────────────

class Recipe:
	var result_id: String
	var result_qty: int
	var ingredients: Array  # [{id, qty}]
	var display_name: String
	var description: String

	func _init(p_result, p_qty, p_ingredients, p_name="", p_desc=""):
		result_id    = p_result
		result_qty   = p_qty
		ingredients  = p_ingredients
		display_name = p_name
		description  = p_desc

# ─── Registries ───────────────────────────────────────────────────────────────

var items: Dictionary   = {}   # id -> ItemDef
var recipes: Array      = []   # Array[Recipe]

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_register_items()
	_register_recipes()

# ─── Item registration ────────────────────────────────────────────────────────

func _register_items() -> void:
	var defs: Array = [
		# RECAMBIOS
		ItemDef.new("pieza_motor",    "Pieza de Motor",    "Componente mecánico básico.",              Category.RECAMBIOS,     "res://assets/icons/pieza_motor.png",    99, false, false, false),
		ItemDef.new("servo_roto",     "Servo Roto",        "Servo dañado, aún recuperable.",           Category.RECAMBIOS,     "res://assets/icons/servo_roto.png",     99, false, false, false),
		ItemDef.new("cable_flex",     "Cable Flex",        "Cable flexible conductor.",                Category.RECAMBIOS,     "res://assets/icons/cable_flex.png",     99, false, false, false),
		ItemDef.new("placa_base",     "Placa Base",        "Circuito impreso reutilizable.",           Category.RECAMBIOS,     "res://assets/icons/placa_base.png",     30, false, false, false),
		# ENERGIA
		ItemDef.new("pila_ion",       "Pila de Ión",       "Batería de litio recargable.",             Category.ENERGIA,       "res://assets/icons/pila_ion.png",       99, false, false, true),
		ItemDef.new("celula_solar",   "Célula Solar",      "Convierte luz en energía.",                Category.ENERGIA,       "res://assets/icons/celula_solar.png",   20, false, false, true),
		ItemDef.new("supercap",       "Supercondensador",  "Almacena energía de forma instantánea.",   Category.ENERGIA,       "res://assets/icons/supercap.png",       10, false, false, true),
		# COMPONENTES
		ItemDef.new("chip_logica",    "Chip Lógica",       "Microprocesador básico.",                  Category.COMPONENTES,   "res://assets/icons/chip_logica.png",    99, false, false, false),
		ItemDef.new("sensor_ir",      "Sensor IR",         "Detecta calor e infrarrojos.",             Category.COMPONENTES,   "res://assets/icons/sensor_ir.png",      50, false, false, false),
		ItemDef.new("motor_micro",    "Micro Motor",       "Motor eléctrico de precisión.",            Category.COMPONENTES,   "res://assets/icons/motor_micro.png",    50, false, false, false),
		ItemDef.new("gyro",           "Giroscopio",        "Mide orientación angular.",                Category.COMPONENTES,   "res://assets/icons/gyro.png",           20, false, false, false),
		# MÓDULOS (equipables)
		ItemDef.new("mod_escudo",     "Módulo Escudo",     "Genera un campo de fuerza temporal.",      Category.MODULOS,       "res://assets/icons/mod_escudo.png",      1, false, true,  false),
		ItemDef.new("mod_propulsor",  "Módulo Propulsor",  "Aumenta la velocidad de movimiento.",      Category.MODULOS,       "res://assets/icons/mod_propulsor.png",   1, false, true,  false),
		ItemDef.new("mod_vision",     "Módulo Visión",     "Amplía el rango de visión del robot.",     Category.MODULOS,       "res://assets/icons/mod_vision.png",      1, false, true,  false),
		ItemDef.new("mod_laser",      "Módulo Láser",      "Emite un haz de corte de alta energía.",   Category.MODULOS,       "res://assets/icons/mod_laser.png",       1, false, true,  false),
		# OBJETOS CLAVE
		ItemDef.new("llave_factoria", "Llave Factoría",    "Acceso a la planta abandonada.",           Category.OBJETOS_CLAVE, "res://assets/icons/llave_factoria.png",  1, true,  false, false),
		ItemDef.new("mapa_sector_b",  "Mapa Sector B",     "Mapa del sector B desencriptado.",         Category.OBJETOS_CLAVE, "res://assets/icons/mapa_sector_b.png",   1, true,  false, false),
	]
	for i in defs.size():
		defs[i].sort_index = i
		items[defs[i].id] = defs[i]

# ─── Recipe registration ──────────────────────────────────────────────────────

func _register_recipes() -> void:
	recipes = [
		Recipe.new("mod_escudo",    1,
			[{"id":"placa_base","qty":2},{"id":"cable_flex","qty":3},{"id":"chip_logica","qty":1}],
			"Módulo Escudo",
			"Crea un módulo de escudo de energía."),
		Recipe.new("mod_propulsor", 1,
			[{"id":"motor_micro","qty":2},{"id":"pila_ion","qty":1},{"id":"pieza_motor","qty":3}],
			"Módulo Propulsor",
			"Crea un módulo de propulsión mejorada."),
		Recipe.new("mod_vision",    1,
			[{"id":"sensor_ir","qty":2},{"id":"chip_logica","qty":2},{"id":"gyro","qty":1}],
			"Módulo Visión",
			"Crea un módulo amplificador de visión."),
		Recipe.new("mod_laser",     1,
			[{"id":"celula_solar","qty":2},{"id":"supercap","qty":1},{"id":"chip_logica","qty":3}],
			"Módulo Láser",
			"Crea un módulo de corte láser."),
		Recipe.new("supercap",      1,
			[{"id":"pila_ion","qty":3},{"id":"placa_base","qty":1}],
			"Supercondensador",
			"Sintetiza un supercondensador de alta capacidad."),
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
