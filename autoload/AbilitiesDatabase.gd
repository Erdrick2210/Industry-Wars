## AbilityDatabase.gd
## Autoload — carga abilities.txt y expone las definiciones de cada habilidad.
## Añadir en Project > Autoload con nombre "AbilityDB"
##
## abilities.txt esperado:
##   [ID_HABILIDAD]
##   Name=Impulso Vectorial
##   Power=50
##   Accuracy=100
##   EPCost=0
##   Effect=Tiene prioridad.

extends Node

# ─── Definición de Habilidad ──────────────────────────────────────────────────

class AbilityDef:
	var id:       String
	var name:     String
	var power:    int
	var accuracy: int
	var ep_cost:  int
	var effect:   String

# ─── Registry ─────────────────────────────────────────────────────────────────

var ability_defs: Dictionary = {}   # String id -> AbilityDef

const DB_PATH := "res://data/abilities.txt"

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_db()

# ─── Parser ───────────────────────────────────────────────────────────────────

func _load_db() -> void:
	var file := FileAccess.open(DB_PATH, FileAccess.READ)
	if file == null:
		push_error("AbilityDB: no se encontró '%s'" % DB_PATH)
		return

	var current: AbilityDef = null

	while not file.eof_reached():
		var raw := file.get_line().strip_edges()
		if raw.is_empty():
			continue

		# Nuevo bloque [ID]
		if raw.begins_with("[") and raw.ends_with("]"):
			if current != null:
				ability_defs[current.id] = current
			current       = AbilityDef.new()
			current.id    = raw.trim_prefix("[").trim_suffix("]")
			continue

		if current == null:
			continue

		var sep := raw.find("=")
		if sep == -1:
			continue
		var key := raw.left(sep).strip_edges()
		var val := raw.right(raw.length() - sep - 1).strip_edges()

		match key:
			"Name":
				current.name = val
			"Power":
				current.power = int(val)
			"Accuracy":
				# Manejamos posibles valores vacíos como 100% de base
				current.accuracy = int(val) if val.is_valid_int() else 100
			"EPCost":
				current.ep_cost = int(val)
			"Effect":
				current.effect = val

	# Último bloque
	if current != null:
		ability_defs[current.id] = current

	file.close()
	print("AbilityDB: %d habilidades cargadas." % ability_defs.size())

# ─── Helpers ──────────────────────────────────────────────────────────────────

func get_ability(id: String) -> AbilityDef:
	return ability_defs.get(id, null)

func get_all() -> Array:
	return ability_defs.values()
