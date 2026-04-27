## RobotsMenu.gd
## Pantalla de equipo: 4 tarjetas de robot + panel de detalle dinámico.
## Adjuntar a res://scenes/RobotsMenu.tscn
##
## ─── Árbol de nodos requerido ────────────────────────────────────────────────
##
## RobotsMenu (Control)  [este script]       ← anchor Full Rect
## ├── MainContainer (HBoxContainer)         ← separation 0, fill+expand
## │   ├── PartyPanel (VBoxContainer)        ← min-width 260, margin 12
## │   │   ├── TitleLabel (Label)            ← texto "Robots"
## │   │   └── CardList (VBoxContainer)      ← separation 8
## │   │       ├── RobotCard_0 (Panel)  ─┐
## │   │       ├── RobotCard_1 (Panel)   │  ver _build_card()
## │   │       ├── RobotCard_2 (Panel)   │
## │   │       └── RobotCard_3 (Panel)  ─┘
## │   └── DetailPanel (Panel)               ← fill+expand
## │       └── DetailScroll (ScrollContainer)
## │           └── DetailVBox (VBoxContainer) ← margin 16, separation 10
## │               ├── DetailName  (Label)
## │               ├── DetailLevel (Label)
## │               ├── ExpBar      (ProgressBar)
## │               ├── ExpLabel    (Label)
## │               ├── HSeparator
## │               ├── StatsGrid   (GridContainer) ← columns 2
## │               ├── HSeparator
## │               ├── AbilitiesTitle (Label)
## │               └── AbilitiesList  (VBoxContainer)
## ├── BottomBar (HBoxContainer)             ← anchor bottom, height 32
## │   └── CloseBtn (Button)
## └── AnimationPlayer

extends Control

signal closed

# ─── Refs ─────────────────────────────────────────────────────────────────────

@onready var card_list:       VBoxContainer  = $MainContainer/PartyPanel/CardList
@onready var detail_name:     Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/DetailName
@onready var detail_level:    Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/DetailLevel
@onready var exp_bar:         ProgressBar    = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ExpBar
@onready var exp_label:       Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ExpLabel
@onready var stats_grid:      GridContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/StatsGrid
@onready var abilities_list:  VBoxContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/AbilitiesList
@onready var close_btn:       Button         = $BottomBar/CloseBtn
@onready var anim_player:     AnimationPlayer= $AnimationPlayer

# ─── Estado ───────────────────────────────────────────────────────────────────

var _selected_slot: int   = -1
var _cards:         Array = []   # Array[Panel] — una por slot

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_btn.pressed.connect(_close)
	RobotParty.party_changed.connect(_refresh_all)

	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")

	_build_cards()
	_refresh_all()
	if RobotParty.party.size() > 0:
		_select_slot(0)

# ─── Construcción de tarjetas ─────────────────────────────────────────────────

func _build_cards() -> void:
	for c in _cards:
		if is_instance_valid(c):
			c.queue_free()
	_cards.clear()

	for i in 4:
		var card := _make_card(i)
		card_list.add_child(card)
		_cards.append(card)

func _make_card(slot: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 64)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Contenido interno
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)

	# — Sprite placeholder (TextureRect) —
	var sprite := TextureRect.new()
	sprite.name                  = "Sprite"
	sprite.custom_minimum_size   = Vector2(48, 48)
	sprite.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode           = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# — Info (nombre, nivel, HP bar) —
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"

	var level_lbl := Label.new()
	level_lbl.name = "LevelLabel"
	level_lbl.add_theme_font_size_override("font_size", 11)

	var hp_bar := ProgressBar.new()
	hp_bar.name              = "HPBar"
	hp_bar.custom_minimum_size = Vector2(0, 8)
	hp_bar.show_percentage   = false
	hp_bar.add_theme_color_override("fill_color", Color(0.2, 0.8, 0.3))

	info.add_child(name_lbl)
	info.add_child(level_lbl)
	info.add_child(hp_bar)
	hbox.add_child(sprite)
	hbox.add_child(info)
	card.add_child(hbox)

	# Click
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style_clear := StyleBoxFlat.new()
	style_clear.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal",  style_clear)
	btn.add_theme_stylebox_override("hover",   style_clear)
	btn.add_theme_stylebox_override("pressed", style_clear)
	btn.add_theme_stylebox_override("focus",   style_clear)
	btn.flat = true
	btn.pressed.connect(_select_slot.bind(slot))
	card.add_child(btn)

	return card

# ─── Refresco global ──────────────────────────────────────────────────────────

func _refresh_all() -> void:
	for i in 4:
		_refresh_card(i)
	if _selected_slot >= 0:
		_refresh_detail(_selected_slot)

# ─── Refresco de tarjeta ──────────────────────────────────────────────────────

func _refresh_card(slot: int) -> void:
	if slot >= _cards.size():
		return
	var card := _cards[slot] as Panel
	if card == null:
		return

	var hbox      := card.get_child(0) as HBoxContainer
	var info_box  := hbox.get_child(1) as VBoxContainer
	var name_lbl  := info_box.get_child(0) as Label
	var level_lbl := info_box.get_child(1) as Label
	var hp_bar    := info_box.get_child(2) as ProgressBar

	if slot >= RobotParty.party.size():
		# Slot vacío
		name_lbl.text  = "— Vacío —"
		level_lbl.text = ""
		hp_bar.value   = 0
		hp_bar.max_value = 1
		card.modulate  = Color(0.5, 0.5, 0.5, 0.6)
		return

	var robot: RobotParty.RobotInstance = RobotParty.party[slot] as RobotParty.RobotInstance
	card.modulate = Color(1.3, 1.3, 0.7) if slot == _selected_slot else Color.WHITE

	name_lbl.text  = robot.display_name()
	level_lbl.text = "Nv. %d" % robot.level
	hp_bar.max_value = robot.max_hp
	hp_bar.value     = robot.current_hp

	# Color HP bar según porcentaje
	var hp_pct: float = float(robot.current_hp) / float(robot.max_hp) if robot.max_hp > 0 else 0.0
	var hp_color: Color
	if hp_pct > 0.5:
		hp_color = Color(0.2, 0.8, 0.3)
	elif hp_pct > 0.2:
		hp_color = Color(0.9, 0.7, 0.1)
	else:
		hp_color = Color(0.9, 0.2, 0.2)
	hp_bar.add_theme_color_override("fill_color", hp_color)

# ─── Selección ────────────────────────────────────────────────────────────────

func _select_slot(slot: int) -> void:
	if slot >= RobotParty.party.size():
		return
	_selected_slot = slot
	for i in _cards.size():
		var c := _cards[i] as Panel
		if c:
			c.modulate = Color(1.3, 1.3, 0.7) if i == slot else Color.WHITE
	_refresh_detail(slot)

# ─── Panel de detalle ─────────────────────────────────────────────────────────

func _refresh_detail(slot: int) -> void:
	if slot < 0 or slot >= RobotParty.party.size():
		_clear_detail()
		return

	var robot: RobotParty.RobotInstance = RobotParty.party[slot] as RobotParty.RobotInstance
	var def = RobotDB.get_chassis(robot.chassis_id)

	# — Nombre y nivel —
	detail_name.text  = robot.display_name()
	detail_level.text = "Nivel %d" % robot.level

	# — Barra de EXP —
	var progress: float = RobotParty.level_progress(robot.total_exp)
	exp_bar.value       = progress * 100.0
	exp_bar.max_value   = 100.0
	var exp_next: int   = RobotParty.exp_for_next_level(robot.total_exp)
	exp_label.text      = "EXP: %d  /  %d para nivel %d" % [
		robot.total_exp,
		exp_next,
		robot.level + 1
	]

	# — Stats —
	for child in stats_grid.get_children():
		child.queue_free()

	var stats := [
		["HP",       "%d / %d" % [robot.current_hp, robot.max_hp]],
		["EP",       "%d / %d" % [robot.current_ep, robot.max_ep]],
		["Ataque",   str(robot.attack)],
		["Defensa",  str(robot.defense)],
		["Velocidad",str(robot.speed)],
	]
	for row in stats:
		var key_lbl := Label.new()
		key_lbl.text = row[0]
		key_lbl.add_theme_font_size_override("font_size", 12)
		var val_lbl := Label.new()
		val_lbl.text = row[1]
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(key_lbl)
		stats_grid.add_child(val_lbl)

	# — Habilidades —
	for child in abilities_list.get_children():
		child.queue_free()

	if def == null:
		return

	for ab in def.abilities:
		var lbl          := Label.new()
		var learned: bool = ab["id"] in robot.learned_abilities
		lbl.text          = ("✓ " if learned else "  Nv.%d  " % ab["level"]) + ab["id"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate      = Color.WHITE if learned else Color(0.5, 0.5, 0.5)
		abilities_list.add_child(lbl)

func _clear_detail() -> void:
	detail_name.text  = ""
	detail_level.text = ""
	exp_bar.value     = 0
	exp_label.text    = ""
	for child in stats_grid.get_children():
		child.queue_free()
	for child in abilities_list.get_children():
		child.queue_free()

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_up"):
		_select_slot(max(_selected_slot - 1, 0))
	elif event.is_action_pressed("ui_down"):
		_select_slot(min(_selected_slot + 1, RobotParty.party.size() - 1))

# ─── Close ────────────────────────────────────────────────────────────────────

func _close() -> void:
	if anim_player and anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	closed.emit()
