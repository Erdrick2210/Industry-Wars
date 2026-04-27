## RobotDatabase.gd
## Autoload — carga robots.txt y expone las definiciones de cada chasis.
## Añadir en Project > Autoload con nombre "RobotDB"
##
## robots.txt esperado:
##   [N]
##   Name=Guardián
##   BaseStats=HP,ATK,DEF,EP,SPD
##   GrowthRate=Parabolic
##   BaseEXP=64
##   Abilities=nivel,ID,nivel,ID,...
##   Description=...

extends Node

# ─── Definición de chasis ─────────────────────────────────────────────────────

class ChassisDef:
	var id:          int
	var name:        String
	var description: String
	var base_hp:     int
	var base_atk:    int
	var base_def:    int
	var base_ep:     int
	var base_spd:    int
	var base_exp:    int
	var growth_rate: String
	var abilities:   Array   # [{level, id}]

# ─── Registry ─────────────────────────────────────────────────────────────────

var chassis_defs: Dictionary = {}   # int id -> ChassisDef

const DB_PATH := "res://data/robots.txt"

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_db()

# ─── Parser ───────────────────────────────────────────────────────────────────

func _load_db() -> void:
	var file := FileAccess.open(DB_PATH, FileAccess.READ)
	if file == null:
		push_error("RobotDB: no se encontró '%s'" % DB_PATH)
		return

	var current: ChassisDef = null

	while not file.eof_reached():
		var raw := file.get_line().strip_edges()
		if raw.is_empty():
			continue

		# Nuevo bloque [N]
		if raw.begins_with("[") and raw.ends_with("]"):
			if current != null:
				chassis_defs[current.id] = current
			current       = ChassisDef.new()
			current.id    = int(raw.trim_prefix("[").trim_suffix("]"))
			current.abilities = []
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
			"Description":
				current.description = val
			"GrowthRate":
				current.growth_rate = val
			"BaseEXP":
				current.base_exp = int(val)
			"BaseStats":
				# HP, ATK, DEF, EP, SPD
				var parts := val.split(",")
				if parts.size() >= 5:
					current.base_hp  = int(parts[0])
					current.base_atk = int(parts[1])
					current.base_def = int(parts[2])
					current.base_ep  = int(parts[3])
					current.base_spd = int(parts[4])
			"Abilities":
				var parts := val.split(",")
				var i := 0
				while i + 1 < parts.size():
					current.abilities.append({
						"level": int(parts[i]),
						"id":    parts[i + 1].strip_edges()
					})
					i += 2

	# Último bloque
	if current != null:
		chassis_defs[current.id] = current

	file.close()
	print("RobotDB: %d chasis cargados." % chassis_defs.size())

# ─── Helpers ──────────────────────────────────────────────────────────────────

func get_chassis(id: int) -> ChassisDef:
	return chassis_defs.get(id, null)

func get_all() -> Array:
	return chassis_defs.values()
