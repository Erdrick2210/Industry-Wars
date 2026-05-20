## TallerMenu.gd  (v2)
## Adjuntar a res://scenes/TallerMenu.tscn
##
## Soporta dos tipos de recetas:
##   - ItemDB.Recipe    → produce ítems normales (munición, módulos de bolsa)
##   - ModuleRecipe     → produce módulos/núcleos de ModuleDB (se guardan en Inventory
##                        como ítems con categoría MODULOS o NUCLEOS)
##
## Al craftear:
##   · Los ingredientes se descuentan del inventario (Inventory.remove_item)
##   · El resultado se añade al inventario (Inventory.add_item)
##   · Si el resultado es un módulo/núcleo de ModuleDB, se registra dinámicamente
##     en ItemDB para que la bolsa lo muestre y permita equiparlo

extends Control

signal closed

# ─── Receta de módulo (ModuleDB) ──────────────────────────────────────────────

class ModuleRecipe:
	var result_id:    String   # ID en ModuleDB (módulo o núcleo)
	var result_type:  String   # "module" | "core"
	var display_name: String
	var description:  String
	var ingredients:  Array    # [{id, qty}]  — ids de ItemDB

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var recipe_list:    VBoxContainer  = $SplitContainer/LeftPanel/RecipeScroll/RecipeList
@onready var recipe_name:    Label          = $SplitContainer/RightPanel/VBox/RecipeName
@onready var recipe_desc:    Label          = $SplitContainer/RightPanel/VBox/RecipeDesc
@onready var ingr_container: VBoxContainer  = $SplitContainer/RightPanel/VBox/IngredientsBox
@onready var result_preview: Label          = $SplitContainer/RightPanel/VBox/ResultPreview
@onready var craft_btn:      Button         = $SplitContainer/RightPanel/VBox/CraftBtn
@onready var close_btn:      Button         = $BottomBar/CloseBtn
@onready var anim_player:    AnimationPlayer= $AnimationPlayer
@onready var feedback_label: Label          = $SplitContainer/RightPanel/VBox/FeedbackLabel

# ─── Estado ───────────────────────────────────────────────────────────────────

## Cada entrada es ItemDB.Recipe o ModuleRecipe
var _all_recipes:  Array = []
var _selected_idx: int   = -1
var _recipe_btns:  Array = []

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_btn.pressed.connect(_close)
	craft_btn.pressed.connect(_on_craft_pressed)
	Inventory.inventory_changed.connect(_refresh_detail)
	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")
	feedback_label.text = ""
	_load_recipes()

# ─── Carga de recetas ─────────────────────────────────────────────────────────

func _load_recipes() -> void:
	_all_recipes.clear()
	for b in _recipe_btns:
		if is_instance_valid(b): b.queue_free()
	_recipe_btns.clear()

	# 1. Recetas de ItemDB (munición, componentes crafteables...)
	for r in ItemDB.get_all_craftable():
		_all_recipes.append(r)

	# 2. Recetas de módulos (ModuleDB) — definidas aquí
	for mr in _build_module_recipes():
		_all_recipes.append(mr)

	# Construir botones
	for i in _all_recipes.size():
		var recipe = _all_recipes[i]
		var btn    := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		if recipe is ItemDB.Recipe:
			btn.text = recipe.display_name
		else:
			var mr := recipe as ModuleRecipe
			btn.text = mr.display_name
		btn.pressed.connect(_select_recipe.bind(i))
		btn.focus_entered.connect(_select_recipe.bind(i))
		recipe_list.add_child(btn)
		_recipe_btns.append(btn)

	if _all_recipes.size() > 0:
		_select_recipe(0)

## Define las recetas de módulos y núcleos.
## Añade aquí nuevas entradas cuando crees módulos nuevos en modules.txt / cores.txt.
func _build_module_recipes() -> Array:
	return [
		# ── Núcleos ──────────────────────────────────────────────────────────
		_mr("NUCLEO_LOGISTICO",  "core", "Núcleo Logístico",  "Alta Velocidad. +25 VEL -10 DEF.",
			[{"id":"chip_logica","qty":2},{"id":"motor_micro","qty":1},{"id":"cable_flex","qty":3}]),
		_mr("NUCLEO_PRODUCTIVO", "core", "Núcleo Productivo", "Ataque. +25 ATK -15 HP.",
			[{"id":"chip_logica","qty":2},{"id":"pieza_motor","qty":3},{"id":"placa_base","qty":1}]),
		_mr("NUCLEO_RECICLADOR", "core", "Núcleo Reciclador", "Recuperación HP. +30 HP -10 EP.",
			[{"id":"cable_flex","qty":2},{"id":"sensor_ir","qty":2},{"id":"placa_base","qty":1}]),
		_mr("NUCLEO_ENERGETICO", "core", "Núcleo Energético", "Mayor EP. +20 EP -10 ATK.",
			[{"id":"celula_solar","qty":2},{"id":"chip_logica","qty":1},{"id":"cable_flex","qty":2}]),

		# ── Módulos ofensivos ────────────────────────────────────────────────
		_mr("MOD_SOBRECARGADOR_CINETICO", "module", "Sobrecargador Cinético", "+20 ATK -10 DEF.",
			[{"id":"pieza_motor","qty":2},{"id":"chip_logica","qty":1},{"id":"cable_flex","qty":1}]),
		_mr("MOD_PROYECTOR_IMPACTO",      "module", "Proyector de Impacto",   "Habilidad: Disparo Perforante.",
			[{"id":"chip_logica","qty":2},{"id":"sensor_ir","qty":1},{"id":"placa_base","qty":1}]),
		_mr("MOD_NUCLEO_COMBATE",         "module", "Núcleo de Combate",      "Habilidad: Embate Brutal.",
			[{"id":"pieza_motor","qty":3},{"id":"motor_micro","qty":1},{"id":"chip_logica","qty":1}]),

		# ── Módulos defensivos ───────────────────────────────────────────────
		_mr("MOD_PLACAS_REFORZADAS",   "module", "Placas Reforzadas",    "+25 DEF -10 VEL.",
			[{"id":"placa_base","qty":2},{"id":"cable_flex","qty":2},{"id":"servo_roto","qty":1}]),
		_mr("MOD_MINERAL_ENDURECEDOR", "module", "Mineral Endurecedor",  "Habilidad: Campo de Mitigación.",
			[{"id":"placa_base","qty":1},{"id":"sensor_ir","qty":1},{"id":"cable_flex","qty":2}]),
		_mr("MOD_ABSORBEDOR_IMPACTO",  "module", "Absorbedor de Impacto","-15% daño crítico recibido.",
			[{"id":"servo_roto","qty":2},{"id":"cable_flex","qty":1},{"id":"chip_logica","qty":1}]),

		# ── Módulos energéticos ──────────────────────────────────────────────
		_mr("MOD_CONDENSADOR_EXPANDIDO","module","Condensador Expandido","+30 EP máximo.",
			[{"id":"celula_solar","qty":1},{"id":"placa_base","qty":1},{"id":"cable_flex","qty":2}]),
		_mr("MOD_REACTOR_AUXILIAR",     "module","Reactor Auxiliar",     "+5 EP por turno.",
			[{"id":"celula_solar","qty":2},{"id":"chip_logica","qty":1}]),
		_mr("MOD_CARGADOR_EXTERNO",     "module","Cargador Externo",     "Habilidad: Pulso de Recarga.",
			[{"id":"supercap","qty":1},{"id":"celula_solar","qty":1},{"id":"chip_logica","qty":1}]),

		# ── Módulos tácticos ─────────────────────────────────────────────────
		_mr("MOD_PROPULSORES_VECTORIALES","module","Propulsores Vectoriales","+20 VEL.",
			[{"id":"motor_micro","qty":2},{"id":"cable_flex","qty":1}]),
		_mr("MOD_DISTORSIONADOR_OPTICO",  "module","Distorsionador Óptico",  "Habilidad: Espejismo Ilusorio.",
			[{"id":"chip_logica","qty":2},{"id":"gyro","qty":1},{"id":"cable_flex","qty":1}]),
		_mr("MOD_INTERFERIDOR_NEURAL",    "module","Interferidor Neural",    "Habilidad: Deterioro Acelerado.",
			[{"id":"chip_logica","qty":2},{"id":"sensor_ir","qty":1},{"id":"gyro","qty":1}]),
	]

## Helper para construir ModuleRecipe de forma compacta.
func _mr(id: String, type: String, name: String, desc: String, ings: Array) -> ModuleRecipe:
	var r          := ModuleRecipe.new()
	r.result_id    = id
	r.result_type  = type
	r.display_name = name
	r.description  = desc
	r.ingredients  = ings
	return r

# ─── Selección ────────────────────────────────────────────────────────────────

func _select_recipe(idx: int) -> void:
	_selected_idx       = idx
	feedback_label.text = ""
	for i in _recipe_btns.size():
		var btn := _recipe_btns[i] as Button
		if btn:
			btn.modulate = Color(1.2, 1.2, 0.8) if i == idx else Color.WHITE
	_refresh_detail()

# ─── Panel de detalle ─────────────────────────────────────────────────────────

func _refresh_detail() -> void:
	if _selected_idx < 0 or _selected_idx >= _all_recipes.size():
		return

	var recipe    = _all_recipes[_selected_idx]
	var name_str: String
	var desc_str: String
	var ings:     Array
	var result_id: String

	if recipe is ItemDB.Recipe:
		var r       := recipe as ItemDB.Recipe
		name_str    = r.display_name
		desc_str    = r.description
		ings        = r.ingredients
		result_id   = r.result_id
	else:
		var mr      := recipe as ModuleRecipe
		name_str    = mr.display_name
		desc_str    = mr.description
		ings        = mr.ingredients
		result_id   = mr.result_id

	recipe_name.text = name_str
	recipe_desc.text = desc_str

	# Preview del resultado
	result_preview.text = _result_preview(recipe)

	# Ingredientes
	for child in ingr_container.get_children():
		child.queue_free()

	var can_craft := true
	for ing in ings:
		var ing_def  = ItemDB.get_item(ing.id)
		var have:int = Inventory.count_item(ing.id)
		var need:int = ing.qty
		var is_ok: bool = have >= need

		var row      := HBoxContainer.new()
		var n_lbl    := Label.new()
		var c_lbl    := Label.new()
		n_lbl.text    = (ing_def.display_name if ing_def else ing.id) + ":"
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_lbl.text    = "%d / %d" % [have, need]
		c_lbl.modulate = Color.GREEN if is_ok else Color.RED
		row.add_child(n_lbl)
		row.add_child(c_lbl)
		ingr_container.add_child(row)

		if not is_ok:
			can_craft = false

	craft_btn.disabled = not can_craft

## Texto de preview del resultado (cantidad en inventario actual).
func _result_preview(recipe) -> String:
	var result_id: String
	var name_str:  String
	if recipe is ItemDB.Recipe:
		var r    := recipe as ItemDB.Recipe
		result_id = r.result_id
		var def   = ItemDB.get_item(result_id)
		name_str  = def.display_name if def else result_id
	else:
		var mr    := recipe as ModuleRecipe
		result_id  = mr.result_id
		name_str   = mr.display_name

	var have: int = Inventory.count_item(result_id)
	return "Resultado: %s  (tienes: %d)" % [name_str, have]

# ─── Craftear ─────────────────────────────────────────────────────────────────

func _on_craft_pressed() -> void:
	if _selected_idx < 0:
		return
	var recipe = _all_recipes[_selected_idx]

	if recipe is ItemDB.Recipe:
		_craft_item_recipe(recipe as ItemDB.Recipe)
	else:
		_craft_module_recipe(recipe as ModuleRecipe)

## Crafteo de receta normal de ItemDB.
func _craft_item_recipe(recipe: ItemDB.Recipe) -> void:
	if Inventory.craft(recipe):
		var def      = ItemDB.get_item(recipe.result_id)
		var name_str: String = def.display_name if def else recipe.result_id
		_show_feedback("✓ %s fabricado!" % name_str, Color.GREEN)
	else:
		_show_feedback("✗ Componentes insuficientes.", Color.RED)

## Crafteo de módulo/núcleo de ModuleDB.
## 1. Descuenta ingredientes del inventario.
## 2. Registra el resultado en ItemDB si aún no existe (para la bolsa).
## 3. Añade 1 unidad al inventario.
func _craft_module_recipe(mr: ModuleRecipe) -> void:
	# Comprobar ingredientes
	for ing in mr.ingredients:
		if Inventory.count_item(ing.id) < ing.qty:
			_show_feedback("✗ Componentes insuficientes.", Color.RED)
			return

	# Descontar ingredientes
	for ing in mr.ingredients:
		Inventory.remove_item(ing.id, ing.qty)

	# Asegurar que el resultado existe en ItemDB (registro dinámico)
	_ensure_item_registered(mr)

	# Añadir al inventario
	Inventory.add_item(mr.result_id, 1)

	_show_feedback("✓ %s fabricado!" % mr.display_name, Color.GREEN)

## Registra un módulo/núcleo en ItemDB si todavía no está,
## de modo que la Bolsa pueda mostrarlo y permitir equiparlo.
func _ensure_item_registered(mr: ModuleRecipe) -> void:
	if ItemDB.get_item(mr.result_id) != null:
		return   # ya registrado

	var cat: int
	var bonus: Dictionary = {}

	if mr.result_type == "core":
		cat = ItemDB.Category.MODULOS
		var core = ModuleDB.get_core(mr.result_id)
		if core:
			bonus = core.modifiers.duplicate()
	else:
		cat = ItemDB.Category.MODULOS
		var mod = ModuleDB.get_module(mr.result_id)
		if mod:
			bonus = mod.modifiers.duplicate()
			if mod.type == "active" and not mod.skill_id.is_empty():
				bonus["unlocks_ability"] = mod.skill_id

	var def := ItemDB.ItemDef.new(
		mr.result_id,
		mr.display_name,
		mr.description,
		cat,
		"res://assets/icons/%s.png" % mr.result_id.to_lower(),
		1,       # max_stack
		false,   # is_key_item
		true,    # can_equip
		false,   # can_use
		{},      # use_effect
		bonus
	)
	def.sort_index = ItemDB.items.size()
	ItemDB.items[mr.result_id] = def

# ─── Feedback ─────────────────────────────────────────────────────────────────

func _show_feedback(msg: String, color: Color) -> void:
	feedback_label.text     = msg
	feedback_label.modulate = color

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_up"):
		if _selected_idx > 0:
			_select_recipe(_selected_idx - 1)
	elif event.is_action_pressed("ui_down"):
		if _selected_idx < _all_recipes.size() - 1:
			_select_recipe(_selected_idx + 1)

# ─── Close ────────────────────────────────────────────────────────────────────

func _close() -> void:
	if anim_player and anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	closed.emit()

# =============================================================================
# NODO NUEVO en TallerMenu.tscn respecto a v1:
#   ResultPreview (Label) — añadir en RightPanel/VBox entre RecipeDesc y IngredientsBox
#   texto vacío, color gris claro, muestra "Resultado: X (tienes: N)"
# =============================================================================
