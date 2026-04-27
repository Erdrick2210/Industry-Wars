## TallerMenu.gd
## Taller de crafteo de módulos estilo Pokémon.
## Adjuntar a res://scenes/TallerMenu.tscn
##
## Nodos requeridos en la escena:
##   VBoxContainer  (recipe_list)     — lista de módulos crafteables
##   Label          (recipe_name)     — nombre del módulo seleccionado
##   Label          (recipe_desc)     — descripción
##   VBoxContainer  (ingredients_container) — filas de ingredientes
##   Button         (craft_btn)       — "Fabricar"
##   Button         (close_btn)
##   AnimationPlayer (anim_player)

extends Control

signal closed

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var recipe_list:   VBoxContainer  = $SplitContainer/LeftPanel/RecipeScroll/RecipeList
@onready var recipe_name:   Label          = $SplitContainer/RightPanel/VBox/RecipeName
@onready var recipe_desc:   Label          = $SplitContainer/RightPanel/VBox/RecipeDesc
@onready var ingr_container:VBoxContainer  = $SplitContainer/RightPanel/VBox/IngredientsBox
@onready var craft_btn:     Button         = $SplitContainer/RightPanel/VBox/CraftBtn
@onready var close_btn:     Button         = $BottomBar/CloseBtn
@onready var anim_player:   AnimationPlayer= $AnimationPlayer
@onready var feedback_label:Label          = $SplitContainer/RightPanel/VBox/FeedbackLabel

# ─── State ────────────────────────────────────────────────────────────────────

var _all_recipes:  Array = []
var _selected_idx: int   = -1
var _recipe_btns:  Array = []

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_btn.pressed.connect(_close)
	craft_btn.pressed.connect(_on_craft_pressed)
	Inventory.inventory_changed.connect(_refresh_detail)
	if anim_player:
		anim_player.play("slide_in")
	feedback_label.text = ""
	_load_recipes()

# ─── Load recipes ─────────────────────────────────────────────────────────────

func _load_recipes() -> void:
	_all_recipes = ItemDB.get_all_craftable()
	for b in _recipe_btns:
		b.queue_free()
	_recipe_btns.clear()

	for i in _all_recipes.size():
		var recipe = _all_recipes[i]
		var btn    := Button.new()
		btn.text   = recipe.display_name
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_select_recipe.bind(i))
		btn.focus_entered.connect(_select_recipe.bind(i))
		recipe_list.add_child(btn)
		_recipe_btns.append(btn)

	if _all_recipes.size() > 0:
		_select_recipe(0)

# ─── Select recipe ────────────────────────────────────────────────────────────

func _select_recipe(idx: int) -> void:
	_selected_idx = idx
	feedback_label.text = ""

	# Highlight button
	for i in _recipe_btns.size():
		var btn := _recipe_btns[i] as Button
		if btn:
			btn.modulate = Color.WHITE if i != idx else Color(1.2, 1.2, 0.8)

	_refresh_detail()

# ─── Refresh detail panel ─────────────────────────────────────────────────────

func _refresh_detail() -> void:
	if _selected_idx < 0 or _selected_idx >= _all_recipes.size():
		return
	var recipe = _all_recipes[_selected_idx]
	var result_def = ItemDB.get_item(recipe.result_id)

	recipe_name.text = recipe.display_name
	recipe_desc.text = recipe.description if recipe.description else (result_def.description if result_def else "")

	# Clear old ingredient rows
	for child in ingr_container.get_children():
		child.queue_free()

	var can_craft := true
	for ing in recipe.ingredients:
		var ing_def     = ItemDB.get_item(ing.id)
		var have        = Inventory.count_item(ing.id)
		var needed      = ing.qty
		var is_ok       = have >= needed

		var row         := HBoxContainer.new()
		var name_lbl    := Label.new()
		var count_lbl   := Label.new()

		name_lbl.text   = (ing_def.display_name if ing_def else ing.id) + ":"
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count_lbl.text  = "%d / %d" % [have, needed]
		count_lbl.modulate = Color.GREEN if is_ok else Color.RED

		row.add_child(name_lbl)
		row.add_child(count_lbl)
		ingr_container.add_child(row)

		if not is_ok:
			can_craft = false

	craft_btn.disabled = not can_craft

# ─── Craft ────────────────────────────────────────────────────────────────────

func _on_craft_pressed() -> void:
	if _selected_idx < 0:
		return
	var recipe = _all_recipes[_selected_idx]
	if Inventory.craft(recipe):
		var result_def = ItemDB.get_item(recipe.result_id)
		feedback_label.text = "✓ %s fabricado!" % (result_def.display_name if result_def else recipe.result_id)
		feedback_label.modulate = Color.GREEN
	else:
		feedback_label.text = "✗ Componentes insuficientes."
		feedback_label.modulate = Color.RED

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
	if anim_player:
		anim_player.play("slide_out")
		await anim_player.animation_finished
	closed.emit()
