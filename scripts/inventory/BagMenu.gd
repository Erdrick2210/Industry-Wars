## BagMenu.gd  (v2)
## Layout fiel a la imagen de referencia:
##   - Panel izquierdo: sprite de bolsa grande (cambia según categoría) +
##     lista de ítems superpuesta sobre el área blanca del sprite
##   - Barra superior: flechas < > + nombre de categoría + OptionButton de orden
##   - Panel derecho: descripción del ítem seleccionado + botón acción
##
## Adjuntar a res://scenes/BagMenu.tscn
## Ver el árbol de nodos al final del archivo.

extends Control

signal closed

# ─── Datos de categoría ───────────────────────────────────────────────────────

const CATEGORY_DATA: Array = [
	{ "name": "Recambios",   "bag": "res://assets/art/ui/bag1.PNG", "bg": "res://assets/art/ui/bagbg1.png" },
	{ "name": "Energía",     "bag": "res://assets/art/ui/bag2.PNG", "bg": "res://assets/art/ui/bagbg2.png" },
	{ "name": "Componentes", "bag": "res://assets/art/ui/bag3.PNG", "bg": "res://assets/art/ui/bagbg3.png" },
	{ "name": "Módulos",     "bag": "res://assets/art/ui/bag4.PNG", "bg": "res://assets/art/ui/bagbg4.png" },
	{ "name": "Obj. Clave",  "bag": "res://assets/art/ui/bag1.PNG", "bg": "res://assets/art/ui/bagbg1.png" },
]

# ─── Refs de nodos ────────────────────────────────────────────────────────────

# Panel izquierdo
@onready var bag_sprite:     TextureRect     = $MainContainer/LeftPanel/BagSprite
@onready var bag_bg: TextureRect = $BagBG

# Barra superior (dentro de LeftPanel)
@onready var category_label: Label        = $MainContainer/LeftPanel/TopBar/CategoryLabel
@onready var sort_selector:  OptionButton = $MainContainer/LeftPanel/TopBar/SortSelector
@onready var arrow_left:     Button       = $MainContainer/LeftPanel/TopBar/ArrowLeft
@onready var arrow_right:    Button       = $MainContainer/LeftPanel/TopBar/ArrowRight

# Panel derecho
@onready var item_scroll:    ScrollContainer = $MainContainer/RightPanel/ItemScroll
@onready var item_container: VBoxContainer   = $MainContainer/RightPanel/ItemScroll/ItemContainer

#Panel de Detalles
@onready var detail_name:    Label  = $DetailsContainer/NameDescContainer/NameLabel
@onready var detail_desc:    Label  = $DetailsContainer/NameDescContainer/DescLabel
@onready var detail_qty:     Label  = $DetailsContainer/QtyLabel
@onready var action_btn:     Button = $DetailsContainer/ActionBtn

@onready var anim_player:    AnimationPlayer = $AnimationPlayer

# ─── Estado ───────────────────────────────────────────────────────────────────

var _current_category:  int   = 0
var _current_sort:      int   = ItemDB.SortMode.OBTENCION
var _selected_slot_idx: int   = -1
var _displayed_slots:   Array = []
var _item_buttons:      Array = []

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_sort_options()

	arrow_left.text  = "<"
	arrow_right.text = ">"
	arrow_left.pressed.connect(func():
		_switch_category(wrapi(_current_category - 1, 0, CATEGORY_DATA.size()))
	)
	arrow_right.pressed.connect(func():
		_switch_category(wrapi(_current_category + 1, 0, CATEGORY_DATA.size()))
	)

	action_btn.pressed.connect(_on_action_pressed)
	sort_selector.item_selected.connect(_on_sort_changed)
	Inventory.inventory_changed.connect(_refresh_list)

	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")

	_switch_category(0)

# ─── Sort options ─────────────────────────────────────────────────────────────

func _build_sort_options() -> void:
	sort_selector.add_item("Por obtención")
	sort_selector.add_item("Alfabético")
	sort_selector.add_item("Cantidad")
	sort_selector.selected = 0

# ─── Cambio de categoría ──────────────────────────────────────────────────────

func _switch_category(idx: int) -> void:
	_current_category  = idx
	_selected_slot_idx = -1

	var data: Dictionary = CATEGORY_DATA[idx]
	bag_sprite.texture   = load(data["bag"]) as Texture2D
	bag_bg.texture = load(data["bg"]) as Texture2D
	category_label.text  = data["name"]

	_refresh_list()

# ─── Refresco de lista ────────────────────────────────────────────────────────

func _refresh_list() -> void:
	for b in _item_buttons:
		if is_instance_valid(b):
			b.queue_free()
	_item_buttons.clear()
	_displayed_slots.clear()

	var cat: int = ItemDB.Category.values()[_current_category]
	_displayed_slots = Inventory.get_slots_for_category(cat, _current_sort)

	if _displayed_slots.is_empty():
		var lbl := Label.new()
		lbl.text = "— Vacío —"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
		item_container.add_child(lbl)
		_item_buttons.append(lbl)
		_clear_detail()
		return

	for i in _displayed_slots.size():
		var slot: Inventory.Slot  = _displayed_slots[i] as Inventory.Slot
		var def                   = ItemDB.get_item(slot.item_id)
		if def == null:
			continue

		var btn = Button.new()

		# 1. Ajustes de tamaño y alineación
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 36) # Un poco más alto para los bordes
		btn.alignment             = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode            = Control.FOCUS_ALL

		# 2. Crear el Estilo Normal (Fondo blanco, borde negro)
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color.WHITE
		style_normal.border_color = Color("#282828") # Gris muy oscuro/Negro
		style_normal.set_border_width_all(2)
		style_normal.corner_radius_top_left = 4
		style_normal.corner_radius_top_right = 4
		style_normal.corner_radius_bottom_left = 4
		style_normal.corner_radius_bottom_right = 4
		style_normal.anti_aliasing = false # Clave para el aspecto Pixel Art
		style_normal.content_margin_left = 12 # Sangría para el texto

		# 3. Crear el Estilo Focus/Hover (Fondo crema/amarillento, borde rojo/oscuro)
		var style_focus = style_normal.duplicate()
		style_focus.bg_color = Color("#f8f8d8") # Color crema clásico de selección
		style_focus.border_color = Color("#d82800") # Borde rojizo para destacar

		# 4. Aplicar los estilos al botón
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_focus)
		btn.add_theme_stylebox_override("pressed", style_focus)
		btn.add_theme_stylebox_override("focus", style_focus)

		# 5. Forzar el color del texto a negro en todos los estados
		var text_color = Color("#202020")
		btn.add_theme_color_override("font_color", text_color)
		btn.add_theme_color_override("font_focus_color", text_color)
		btn.add_theme_color_override("font_hover_color", text_color)
		btn.add_theme_color_override("font_pressed_color", text_color)

		# 6. Lógica de texto original
		var suffix: String = " x%d" % slot.quantity if def.max_stack > 1 else ""
		var star: String   = " ★" if Inventory.is_equipped(slot.item_id) else ""
		btn.text = def.display_name + star + suffix

		# 7. Conectar señales
		btn.pressed.connect(_on_item_selected.bind(i))
		btn.focus_entered.connect(_on_item_selected.bind(i))

		item_container.add_child(btn)
		_item_buttons.append(btn)

	# Restaurar / iniciar selección
	var restore: int = _selected_slot_idx if _selected_slot_idx >= 0 and _selected_slot_idx < _displayed_slots.size() else 0
	_on_item_selected(restore)
	var first := _item_buttons[restore] as Button
	if first:
		first.grab_focus()

# ─── Selección de ítem ────────────────────────────────────────────────────────

func _on_item_selected(idx: int) -> void:
	_selected_slot_idx = idx

	for i in _item_buttons.size():
		var b := _item_buttons[i] as Button
		if b == null:
			continue
		b.modulate = Color(1.3, 1.3, 0.6) if i == idx else Color.WHITE

	if idx < 0 or idx >= _displayed_slots.size():
		_clear_detail()
		return

	var slot: Inventory.Slot = _displayed_slots[idx] as Inventory.Slot
	var def                  = ItemDB.get_item(slot.item_id)
	if def == null:
		_clear_detail()
		return

	detail_name.text = def.display_name
	detail_desc.text = def.description
	detail_qty.text  = "x%d" % Inventory.count_item(slot.item_id)

	action_btn.visible = def.can_use or def.can_equip
	if def.can_equip:
		action_btn.text = "Desequipar" if Inventory.is_equipped(slot.item_id) else "Equipar"
	elif def.can_use:
		action_btn.text = "Usar"

# ─── Acción ───────────────────────────────────────────────────────────────────

func _on_action_pressed() -> void:
	if _selected_slot_idx < 0 or _selected_slot_idx >= _displayed_slots.size():
		return
	var slot: Inventory.Slot = _displayed_slots[_selected_slot_idx] as Inventory.Slot
	var def                  = ItemDB.get_item(slot.item_id)
	if def == null:
		return

	if def.can_equip:
		if Inventory.is_equipped(slot.item_id):
			Inventory.unequip_item(slot.item_id)
		else:
			Inventory.equip_item(slot.item_id)
	elif def.can_use:
		Inventory.use_item(slot.item_id)

# ─── Sort ─────────────────────────────────────────────────────────────────────

func _on_sort_changed(idx: int) -> void:
	match idx:
		0: _current_sort = ItemDB.SortMode.OBTENCION
		1: _current_sort = ItemDB.SortMode.ALFABETICO
		2: _current_sort = ItemDB.SortMode.CANTIDAD
	_refresh_list()

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _clear_detail() -> void:
	detail_name.text   = ""
	detail_desc.text   = ""
	detail_qty.text    = ""
	action_btn.visible = false

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_left"):
		_switch_category(wrapi(_current_category - 1, 0, CATEGORY_DATA.size()))
	elif event.is_action_pressed("ui_right"):
		_switch_category(wrapi(_current_category + 1, 0, CATEGORY_DATA.size()))
	elif event.is_action_pressed("ui_down"):
		_on_item_selected(min(_selected_slot_idx + 1, _displayed_slots.size() - 1))
	elif event.is_action_pressed("ui_up"):
		_on_item_selected(max(_selected_slot_idx - 1, 0))

# ─── Close ────────────────────────────────────────────────────────────────────

func _close() -> void:
	if anim_player and anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	closed.emit()
