## ModuleDatabase.gd
## Autoload "ModuleDB"
## Lee res://data/cores.txt y res://data/modules.txt
##
## ModuleDef ya NO almacena la descripción de la habilidad ni su potencia —
## esos datos viven en abilities.txt y se consultan a través de AbilityDB.
## ModuleDef solo guarda la referencia (Skill=ID) y los overrides de coste
## y cooldown que el módulo impone sobre la habilidad base.

extends Node

# ─── CoreDef ──────────────────────────────────────────────────────────────────

class CoreDef:
	var id:         String
	var name:       String
	var subtitle:   String
	var icon:       String
	var modifiers:  Dictionary   # stat → int (puede ser negativo)
	var passive_id: String       # ID del efecto pasivo; descripción en passives.txt

# ─── ModuleDef ────────────────────────────────────────────────────────────────

class ModuleDef:
	var id:            String
	var name:          String
	var type:          String    # "passive" | "active"
	var category:      String    # "offensive" | "defensive" | "energetic" | "tactical"
	var icon:          String
	var modifiers:     Dictionary
	var passive_id:    String    # ID de efecto pasivo (resuelto en combate)
	var skill_id:      String    # ID de habilidad en abilities.txt (solo activos)
	var skill_cost:    int       # override del coste EP (-1 = usar el de abilities.txt)
	var skill_cooldown:int       # override del cooldown (-1 = usar el de abilities.txt)
	var required_core: String    # vacío = sin restricción
	var stat_slot:     String    # "attack"|"defense"|"speed"|"none"

# ─── Registries ───────────────────────────────────────────────────────────────

var cores:   Dictionary = {}
var modules: Dictionary = {}

const CORES_PATH   := "res://data/cores.txt"
const MODULES_PATH := "res://data/modules.txt"

func _ready() -> void:
	_load_cores()
	_load_modules()

# ─── Parser genérico ──────────────────────────────────────────────────────────

func _parse_file(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ModuleDB: no se encontró '%s'" % path)
		return []
	var blocks: Array       = []
	var current: Dictionary = {}
	while not file.eof_reached():
		var raw := file.get_line().strip_edges()
		if raw.is_empty() or raw.begins_with("#"):
			continue
		if raw.begins_with("[") and raw.ends_with("]"):
			if not current.is_empty():
				blocks.append(current)
			current = { "_id": raw.trim_prefix("[").trim_suffix("]") }
			continue
		var sep := raw.find("=")
		if sep == -1:
			continue
		current[raw.left(sep).strip_edges()] = raw.right(raw.length() - sep - 1).strip_edges()
	if not current.is_empty():
		blocks.append(current)
	file.close()
	return blocks

func _parse_modifiers(raw: String) -> Dictionary:
	var out   := {}
	if raw.is_empty():
		return out
	var parts := raw.split(",")
	var i := 0
	while i + 1 < parts.size():
		out[parts[i].strip_edges()] = int(parts[i + 1].strip_edges())
		i += 2
	return out

# ─── Carga ────────────────────────────────────────────────────────────────────

func _load_cores() -> void:
	for block in _parse_file(CORES_PATH):
		var c        := CoreDef.new()
		c.id          = block.get("_id", "")
		c.name        = block.get("Name", c.id)
		c.subtitle    = block.get("Subtitle", "")
		c.icon        = block.get("Icon", "")
		c.modifiers   = _parse_modifiers(block.get("Modifiers", ""))
		c.passive_id  = block.get("PassiveID", "")
		cores[c.id]   = c
	print("ModuleDB: %d núcleos cargados." % cores.size())

func _load_modules() -> void:
	for block in _parse_file(MODULES_PATH):
		var m              := ModuleDef.new()
		m.id               = block.get("_id", "")
		m.name             = block.get("Name", m.id)
		m.type             = block.get("Type", "passive")
		m.category         = block.get("Category", "")
		m.icon             = block.get("Icon", "")
		m.modifiers        = _parse_modifiers(block.get("Modifiers", ""))
		m.passive_id       = block.get("PassiveID", "")
		m.skill_id         = block.get("Skill", "")
		# -1 significa "usar el valor base de abilities.txt"
		m.skill_cost       = int(block.get("SkillCost",     "-1"))
		m.skill_cooldown   = int(block.get("SkillCooldown", "-1"))
		m.required_core    = block.get("RequiredCore", "")
		m.stat_slot        = block.get("StatSlot", "none")
		modules[m.id]      = m
	print("ModuleDB: %d módulos cargados." % modules.size())

# ─── Helpers ──────────────────────────────────────────────────────────────────

func get_core(id: String) -> CoreDef:
	return cores.get(id, null)

func get_module(id: String) -> ModuleDef:
	return modules.get(id, null)

func get_all_cores() -> Array:
	return cores.values()

func get_all_modules() -> Array:
	return modules.values()

func get_modules_by_category(category: String) -> Array:
	return modules.values().filter(func(m): return m.category == category)

## Resumen legible de modificadores para la UI.
## Ej: "+20 ATK  -10 DEF"
func modifiers_summary(mods: Dictionary) -> String:
	var labels := { "attack": "ATK", "defense": "DEF", "speed": "VEL", "max_hp": "HP", "max_ep": "EP" }
	var parts  := []
	for stat in mods:
		parts.append(("%+d " % int(mods[stat])) + labels.get(stat, stat))
	return "  ".join(parts)

## Coste EP efectivo de un módulo activo:
## usa el override si está definido, si no consulta AbilityDB.
func effective_skill_cost(mod: ModuleDef) -> int:
	if mod.skill_cost >= 0:
		return mod.skill_cost
	# Fallback a AbilityDB cuando esté disponible
	# var ab = AbilityDB.get_ability(mod.skill_id)
	# return ab.ep_cost if ab else 0
	return 0

func effective_skill_cooldown(mod: ModuleDef) -> int:
	if mod.skill_cooldown >= 0:
		return mod.skill_cooldown
	return 0
