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
	{ "name": "Obj. Clave",  "bag": "res://assets/art/ui/bag5.PNG", "bg": "res://assets/art/ui/bagbg5.png" },
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
@onready var detail_bonus:   Label  = $DetailsContainer/NameDescContainer/BonusLabel
@onready var detail_equipped:Label  = $DetailsContainer/EquippedLabel
@onready var feedback_label: Label  = $DetailsContainer/NameDescContainer/FeedbackLabel

@onready var robot_popup:    Panel          = $RobotPopup
@onready var popup_title:    Label          = $RobotPopup/VBox/PopupTitle
@onready var popup_list:     VBoxContainer  = $RobotPopup/VBox/PopupList
@onready var popup_cancel:   Button         = $RobotPopup/VBox/CancelBtn

@onready var anim_player:    AnimationPlayer = $AnimationPlayer
@onready var close_btn:      Button         = $MainContainer/LeftPanel/GoBackBtn

# ─── Estado ───────────────────────────────────────────────────────────────────

var _current_category:  int   = 0
var _current_sort:      int   = ItemDB.SortMode.OBTENCION
var _selected_slot_idx: int   = -1
var _displayed_slots:   Array = []
var _item_buttons:      Array = []
var _pending_action:    String = ""

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
	close_btn.pressed.connect(_close)
	action_btn.pressed.connect(_on_action_pressed)
	sort_selector.item_selected.connect(_on_sort_changed)
	popup_cancel.pressed.connect(_hide_popup)
	Inventory.inventory_changed.connect(_refresh_list)
	robot_popup.hide()
	feedback_label.text = ""
	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")
	_switch_category(0)

# ─── Sort ─────────────────────────────────────────────────────────────────────

func _build_sort_options() -> void:
	sort_selector.add_item("Por obtención")
	sort_selector.add_item("Alfabético")
	sort_selector.add_item("Cantidad")
	sort_selector.selected = 0

# ─── Categoría ────────────────────────────────────────────────────────────────

func _switch_category(idx: int) -> void:
	_current_category   = idx
	_selected_slot_idx  = -1
	feedback_label.text = ""
	var data: Dictionary = CATEGORY_DATA[idx]
	bag_sprite.texture   = load(data["bag"]) as Texture2D
	bag_bg.texture       = load(data["bg"]) as Texture2D
	category_label.text  = data["name"]
	_refresh_list()

# ─── Lista ────────────────────────────────────────────────────────────────────

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
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_container.add_child(lbl)
		_item_buttons.append(lbl)
		_clear_detail()
		return

	for i in _displayed_slots.size():
		var slot: Inventory.Slot = _displayed_slots[i] as Inventory.Slot
		var def                  = ItemDB.get_item(slot.item_id)
		if def == null:
			continue
		var btn                   := Button.new()
		btn.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size    = Vector2(0, 28)
		btn.alignment              = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode             = Control.FOCUS_ALL
		var suffix: String = " x%d" % slot.quantity if def.max_stack > 1 else ""
		var star:   String = " [E]"                 if Inventory.is_equipped(slot.item_id) else ""
		btn.text = def.display_name + star + suffix
		btn.pressed.connect(_on_item_selected.bind(i))
		btn.focus_entered.connect(_on_item_selected.bind(i))
		item_container.add_child(btn)
		_item_buttons.append(btn)

	var restore: int = _selected_slot_idx if _selected_slot_idx >= 0 and _selected_slot_idx < _displayed_slots.size() else 0
	_on_item_selected(restore)
	var first := _item_buttons[restore] as Button
	if first:
		first.grab_focus()

# ─── Selección ────────────────────────────────────────────────────────────────

func _on_item_selected(idx: int) -> void:
	_selected_slot_idx  = idx
	feedback_label.text = ""
	for i in _item_buttons.size():
		var b := _item_buttons[i] as Button
		if b:
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

	# Bonus / efecto
	detail_bonus.text = ""
	if not def.module_bonus.is_empty():
		var lines: Array = []
		if def.module_bonus.has("attack"):          lines.append("+%d ATK" % def.module_bonus["attack"])
		if def.module_bonus.has("defense"):         lines.append("+%d DEF" % def.module_bonus["defense"])
		if def.module_bonus.has("speed"):           lines.append("+%d VEL" % def.module_bonus["speed"])
		if def.module_bonus.has("max_hp"):          lines.append("+%d HP máx." % def.module_bonus["max_hp"])
		if def.module_bonus.has("max_ep"):          lines.append("+%d EP máx." % def.module_bonus["max_ep"])
		if def.module_bonus.has("unlocks_ability"): lines.append("Desbloquea: %s" % def.module_bonus["unlocks_ability"])
		detail_bonus.text = "\n".join(lines)
	elif not def.use_effect.is_empty():
		var lines: Array = []
		if def.use_effect.has("heal_hp"): lines.append("Cura %d HP" % def.use_effect["heal_hp"])
		if def.use_effect.has("heal_ep"): lines.append("Restaura %d EP" % def.use_effect["heal_ep"])
		detail_bonus.text = "\n".join(lines)

	# Robot que lo lleva
	detail_equipped.text = ""
	if Inventory.is_equipped(slot.item_id):
		var rs: int = Inventory.equipped_on(slot.item_id)
		if rs >= 0 and rs < RobotParty.party.size():
			var robot: RobotParty.RobotInstance = RobotParty.party[rs] as RobotParty.RobotInstance
			detail_equipped.text = "Equipado en: %s" % robot.display_name()

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
			Inventory.unequip_module(slot.item_id)
			_show_feedback("Módulo desequipado.", Color.WHITE)
		else:
			_pending_action = "equip"
			_open_robot_popup("¿Equipar en qué robot?")
	elif def.can_use:
		if RobotParty.party.size() == 1:
			_execute_use(slot.item_id, 0)
		else:
			_pending_action = "use"
			_open_robot_popup("¿Usar en qué robot?")

# ─── Popup robot ──────────────────────────────────────────────────────────────

func _open_robot_popup(title: String) -> void:
	popup_title.text = title
	for child in popup_list.get_children():
		child.queue_free()
	for i in RobotParty.party.size():
		var robot: RobotParty.RobotInstance = RobotParty.party[i] as RobotParty.RobotInstance
		var btn := Button.new()
		btn.text = "%s  Nv.%d  HP %d/%d" % [robot.display_name(), robot.level, robot.current_hp, robot.max_hp]
		btn.pressed.connect(_on_popup_robot_selected.bind(i))
		popup_list.add_child(btn)
	robot_popup.show()

func _on_popup_robot_selected(robot_slot: int) -> void:
	_hide_popup()
	if _selected_slot_idx < 0 or _selected_slot_idx >= _displayed_slots.size():
		return
	var slot: Inventory.Slot = _displayed_slots[_selected_slot_idx] as Inventory.Slot
	match _pending_action:
		"use":   _execute_use(slot.item_id, robot_slot)
		"equip": _execute_equip(slot.item_id, robot_slot)
	_pending_action = ""

func _hide_popup() -> void:
	robot_popup.hide()
	_pending_action = ""

# ─── Ejecutar ─────────────────────────────────────────────────────────────────

func _execute_use(item_id: String, robot_slot: int) -> void:
	var robot: RobotParty.RobotInstance = RobotParty.party[robot_slot] as RobotParty.RobotInstance
	if Inventory.use_item(item_id, robot_slot):
		_show_feedback("Usado en %s." % robot.display_name(), Color.GREEN)
	else:
		_show_feedback("No se pudo usar.", Color.RED)

func _execute_equip(item_id: String, robot_slot: int) -> void:
	var robot: RobotParty.RobotInstance = RobotParty.party[robot_slot] as RobotParty.RobotInstance
	if Inventory.equip_module(item_id, robot_slot):
		_show_feedback("Equipado en %s." % robot.display_name(), Color.GREEN)
	else:
		_show_feedback("No se pudo equipar.", Color.RED)

func _show_feedback(msg: String, color: Color) -> void:
	feedback_label.text    = msg
	feedback_label.modulate = color

# ─── Sort ─────────────────────────────────────────────────────────────────────

func _on_sort_changed(idx: int) -> void:
	match idx:
		0: _current_sort = ItemDB.SortMode.OBTENCION
		1: _current_sort = ItemDB.SortMode.ALFABETICO
		2: _current_sort = ItemDB.SortMode.CANTIDAD
	_refresh_list()

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _clear_detail() -> void:
	detail_name.text     = ""
	detail_desc.text     = ""
	detail_qty.text      = ""
	detail_bonus.text    = ""
	detail_equipped.text = ""
	action_btn.visible   = false
	feedback_label.text  = ""

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if robot_popup.visible:
		if event.is_action_pressed("ui_cancel"):
			_hide_popup()
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
