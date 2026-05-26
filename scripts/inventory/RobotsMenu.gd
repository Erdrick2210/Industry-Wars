## RobotsMenu.gd  (v3)
## Novedades:
##   - Sección "Ataques Activos": 4 slots con botón de cambio individual
##   - Sección "Por Aprender": habilidades learned pero no activas
##   - Popup de intercambio: muestra ataques disponibles para sustituir un slot
##   - Correcciones: skill_desc / passive eliminados (solo passive_id / skill_id)

extends Control

signal closed

# ─── Refs principales ─────────────────────────────────────────────────────────

@onready var card_list:         VBoxContainer  = $MainContainer/PartyPanel/CardList
@onready var detail_name:       Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/DetailName
@onready var detail_level:      Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/DetailLevel
@onready var exp_bar:           ProgressBar    = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ExpBar
@onready var exp_label:         Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ExpLabel
@onready var stats_grid:        GridContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/StatsGrid
@onready var abilities_list:    VBoxContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/AbilitiesList

# Equipamiento
@onready var core_name_label:   Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/CoreSection/CoreRow/CoreNameLabel
@onready var core_btn:          Button         = $MainContainer/DetailPanel/DetailScroll/DetailVBox/CoreSection/CoreRow/CoreBtn
@onready var core_stats_label:  Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/CoreSection/CoreStatsLabel
@onready var core_passive_label:Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/CoreSection/CorePassiveLabel
@onready var modules_title:     Label          = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ModulesTitle
@onready var module_slots:      VBoxContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ModuleSlots
@onready var add_module_btn:    Button         = $MainContainer/DetailPanel/DetailScroll/DetailVBox/AddModuleBtn

# Moveset
@onready var active_moves_list: VBoxContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/ActiveMovesList
@onready var available_list:    VBoxContainer  = $MainContainer/DetailPanel/DetailScroll/DetailVBox/AvailableList

# Popup unificado
@onready var equip_popup:        Panel         = $EquipPopup
@onready var equip_popup_title:  Label         = $EquipPopup/VBox/EquipPopupTitle
@onready var equip_popup_items:  VBoxContainer = $EquipPopup/VBox/EquipPopupList/EquipPopupItems
@onready var equip_popup_cancel: Button        = $EquipPopup/VBox/EquipPopupCancel

@onready var close_btn:          Button        = $BottomBar/CloseBtn
@onready var anim_player:        AnimationPlayer = $AnimationPlayer

# ─── Estado ───────────────────────────────────────────────────────────────────

var _selected_slot:    int    = -1
var _cards:            Array  = []
var _popup_mode:       String = ""   # "core" | "module" | "move_swap" | "move_info"
var _pending_move_slot:int    = -1   # slot de active_moves a sustituir
var _pending_robot_slot:int   = -1   # robot al que pertenece el swap en curso

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_btn.pressed.connect(_close)
	core_btn.pressed.connect(_open_core_popup)
	add_module_btn.pressed.connect(_open_module_popup)
	equip_popup_cancel.pressed.connect(_hide_popup)
	RobotParty.party_changed.connect(_refresh_all)

	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")

	equip_popup.hide()
	_build_cards()
	_refresh_all()
	if RobotParty.party.size() > 0:
		_select_slot(0)

# ─── Tarjetas ─────────────────────────────────────────────────────────────────

func _build_cards() -> void:
	for c in _cards:
		if is_instance_valid(c): c.queue_free()
	_cards.clear()
	for i in 4:
		var card := _make_card(i)
		card_list.add_child(card)
		_cards.append(card)

func _make_card(slot: int) -> Panel:
	var card               := Panel.new()
	card.custom_minimum_size = Vector2(0, 64)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)

	var sprite             := TextureRect.new()
	sprite.custom_minimum_size = Vector2(48, 48)
	sprite.stretch_mode    = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var info               := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_lbl  := Label.new(); name_lbl.name  = "NameLabel"
	var level_lbl := Label.new(); level_lbl.name = "LevelLabel"
	level_lbl.add_theme_font_size_override("font_size", 11)
	var hp_bar    := ProgressBar.new()
	hp_bar.name = "HPBar"; hp_bar.custom_minimum_size = Vector2(0, 8); hp_bar.show_percentage = false

	info.add_child(name_lbl); info.add_child(level_lbl); info.add_child(hp_bar)
	hbox.add_child(sprite); hbox.add_child(info)
	card.add_child(hbox)

	var btn  := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	var sc   := StyleBoxFlat.new(); sc.bg_color = Color(0,0,0,0)
	for st in ["normal","hover","pressed","focus"]:
		btn.add_theme_stylebox_override(st, sc)
	btn.pressed.connect(_select_slot.bind(slot))
	card.add_child(btn)
	return card

# ─── Refresco global ──────────────────────────────────────────────────────────

func _refresh_all() -> void:
	for i in 4: _refresh_card(i)
	if _selected_slot >= 0: _refresh_detail(_selected_slot)

func _refresh_card(slot: int) -> void:
	if slot >= _cards.size(): return
	var card      := _cards[slot] as Panel
	var hbox      := card.get_child(0) as HBoxContainer
	var info      := hbox.get_child(1) as VBoxContainer
	var name_lbl  := info.get_child(0) as Label
	var level_lbl := info.get_child(1) as Label
	var hp_bar    := info.get_child(2) as ProgressBar

	if slot >= RobotParty.party.size():
		name_lbl.text = "— Vacío —"; level_lbl.text = ""
		hp_bar.value = 0; hp_bar.max_value = 1
		card.modulate = Color(0.5, 0.5, 0.5, 0.6)
		return

	var robot     := RobotParty.party[slot] as RobotParty.RobotInstance
	card.modulate  = Color(1.3,1.3,0.7) if slot == _selected_slot else Color.WHITE
	name_lbl.text  = robot.display_name()
	level_lbl.text = "Nv. %d" % robot.level
	hp_bar.max_value = robot.max_hp; hp_bar.value = robot.current_hp
	var pct: float = float(robot.current_hp) / float(robot.max_hp) if robot.max_hp > 0 else 0.0
	hp_bar.add_theme_color_override("fill_color",
		Color(0.2,0.8,0.3) if pct > 0.5 else (Color(0.9,0.7,0.1) if pct > 0.2 else Color(0.9,0.2,0.2)))

func _select_slot(slot: int) -> void:
	if slot >= RobotParty.party.size(): return
	_selected_slot = slot
	for i in _cards.size():
		var c := _cards[i] as Panel
		if c: c.modulate = Color(1.3,1.3,0.7) if i == slot else Color.WHITE
	_refresh_detail(slot)

# ─── Detalle completo ─────────────────────────────────────────────────────────

func _refresh_detail(slot: int) -> void:
	if slot < 0 or slot >= RobotParty.party.size(): return
	var robot := RobotParty.party[slot] as RobotParty.RobotInstance
	var def    = RobotDB.get_chassis(robot.chassis_id)

	detail_name.text  = robot.display_name()
	detail_level.text = "Nivel %d" % robot.level
	exp_bar.value     = RobotParty.level_progress(robot.total_exp) * 100.0
	exp_bar.max_value = 100.0
	exp_label.text    = "EXP: %d  /  %d para nivel %d" % [
		robot.total_exp, RobotParty.exp_for_next_level(robot.total_exp), robot.level + 1]

	# Stats
	for c in stats_grid.get_children(): 
		c.queue_free()
	
	var hp_text:  String = "%d/%d" % [robot.current_hp, robot.max_hp]
	var ep_text:  String = "%d/%d" % [robot.current_ep, robot.max_ep]
	var iterable: Array = [
		["HP",        hp_text],
		["EP",        ep_text],
		["Ataque",    str(robot.attack)],
		["Defensa",   str(robot.defense)],
		["Velocidad", str(robot.speed)]]
	for row in iterable:
		var k := Label.new(); 
		k.text = row[0]; 
		k.add_theme_font_size_override("font_size",12)
		var v := Label.new(); v.text = row[1]; 
		v.add_theme_font_size_override("font_size",12)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(k); stats_grid.add_child(v)

	# Por aprender (habilidades de nivel aún no desbloqueadas)
	for c in abilities_list.get_children(): c.queue_free()
	if def:
		for ab in def.abilities:
			if not ab["id"] in robot.learned_abilities:
				var lbl     := Label.new()
				lbl.text     = "  Nv.%d  %s" % [ab["level"], ab["id"]]
				lbl.add_theme_font_size_override("font_size", 12)
				lbl.modulate = Color(0.5, 0.5, 0.5)
				abilities_list.add_child(lbl)

	# Núcleo
	if robot.equipped_core.is_empty():
		core_name_label.text   = "— Sin núcleo —"
		core_stats_label.text  = ""
		core_passive_label.text= ""
		core_btn.text          = "Equipar"
	else:
		var core = ModuleDB.get_core(robot.equipped_core)
		if core:
			core_name_label.text    = "%s %s (%s)" % [core.icon, core.name, core.subtitle]
			core_stats_label.text   = ModuleDB.modifiers_summary(core.modifiers)
			core_passive_label.text = "Pasiva: " + core.passive_id
		core_btn.text = "Cambiar"

	# Módulos
	for c in module_slots.get_children(): c.queue_free()
	for mid in robot.equipped_modules:
		var mod = ModuleDB.get_module(mid)
		if mod == null: continue
		var row       := HBoxContainer.new()
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n_lbl := Label.new(); n_lbl.text = "%s %s" % [mod.icon, mod.name]
		n_lbl.add_theme_font_size_override("font_size", 12)
		var e_lbl := Label.new()
		e_lbl.add_theme_font_size_override("font_size", 11)
		e_lbl.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
		if mod.type == "passive":
			var s := ModuleDB.modifiers_summary(mod.modifiers)
			e_lbl.text = s if not s.is_empty() else mod.passive_id
		else:
			e_lbl.text = "%s  (%d EP)" % [mod.skill_id, ModuleDB.effective_skill_cost(mod)]
		info_vbox.add_child(n_lbl); info_vbox.add_child(e_lbl)
		var u_btn := Button.new(); u_btn.text = "✕"
		u_btn.custom_minimum_size = Vector2(28,28)
		u_btn.pressed.connect(func(): RobotParty.unequip_module_from_robot(slot, mid))
		row.add_child(info_vbox); row.add_child(u_btn)
		module_slots.add_child(row)

	modules_title.text     = "Módulos (%d/3)" % robot.equipped_modules.size()
	add_module_btn.visible = robot.equipped_modules.size() < 3

	# ── Ataques activos ──────────────────────────────────────────────────────
	_refresh_moves(slot)

func _refresh_moves(slot: int) -> void:
	var robot := RobotParty.party[slot] as RobotParty.RobotInstance

	# 4 slots de ataque activo
	for c in active_moves_list.get_children(): c.queue_free()
	for i in 4:
		var row      := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var slot_lbl := Label.new()
		slot_lbl.text = "%d." % (i + 1)
		slot_lbl.custom_minimum_size = Vector2(18, 0)

		var move_lbl := Label.new()
		move_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		move_lbl.add_theme_font_size_override("font_size", 12)

		var has_move: bool = i < robot.active_moves.size() and not robot.active_moves[i].is_empty()

		# Botón info — solo si hay ataque en el slot
		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.custom_minimum_size = Vector2(28, 28)
		info_btn.visible = has_move

		# Botón swap
		var swap_btn := Button.new()
		swap_btn.text = "↔"
		swap_btn.custom_minimum_size = Vector2(28, 28)

		if has_move:
			var ability_id: String = robot.active_moves[i]
			move_lbl.text = ability_id
			info_btn.pressed.connect(_open_move_info_popup.bind(ability_id))
			swap_btn.pressed.connect(_open_move_swap_popup.bind(slot, i))
		else:
			move_lbl.text     = "— vacío —"
			move_lbl.modulate = Color(0.5, 0.5, 0.5)
			if not robot.available_moves().is_empty():
				swap_btn.pressed.connect(_open_move_swap_popup.bind(slot, i))
			else:
				swap_btn.disabled = true

		row.add_child(slot_lbl)
		row.add_child(move_lbl)
		row.add_child(info_btn)
		row.add_child(swap_btn)
		active_moves_list.add_child(row)

	# Ataques aprendidos pero no activos
	for c in available_list.get_children(): c.queue_free()
	var available := robot.available_moves()
	if available.is_empty():
		var lbl     := Label.new()
		lbl.text     = "Todos los ataques aprendidos están activos."
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = Color(0.6, 0.6, 0.6)
		available_list.add_child(lbl)
	else:
		for ab_id in available:
			var row  := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var lbl  := Label.new()
			lbl.text  = ab_id
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.add_theme_font_size_override("font_size", 12)
			var info_btn := Button.new()
			info_btn.text = "?"
			info_btn.custom_minimum_size = Vector2(28, 28)
			info_btn.pressed.connect(_open_move_info_popup.bind(ab_id))
			row.add_child(lbl)
			row.add_child(info_btn)
			available_list.add_child(row)

# ─── Popup núcleo ─────────────────────────────────────────────────────────────

func _open_core_popup() -> void:
	if _selected_slot < 0: return
	_popup_mode = "core"
	equip_popup_title.text = "Selecciona un Núcleo"
	for c in equip_popup_items.get_children(): c.queue_free()
	var robot := RobotParty.party[_selected_slot] as RobotParty.RobotInstance
	for core in ModuleDB.get_all_cores():
		var btn    := Button.new()
		var active: bool = robot.equipped_core == core.id
		btn.text = "%s %s (%s)  %s" % [core.icon, core.name, core.subtitle,
			ModuleDB.modifiers_summary(core.modifiers)]
		if active:
			btn.text    += "  ←"
			btn.modulate = Color(1.2, 1.2, 0.6)
		btn.pressed.connect(_on_core_selected.bind(core.id))
		equip_popup_items.add_child(btn)
	equip_popup.show()

func _on_core_selected(core_id: String) -> void:
	_hide_popup()
	RobotParty.equip_core(_selected_slot, core_id)

# ─── Popup módulo ─────────────────────────────────────────────────────────────

func _open_module_popup() -> void:
	if _selected_slot < 0: return
	_popup_mode = "module"
	equip_popup_title.text = "Selecciona un Módulo"
	for c in equip_popup_items.get_children(): c.queue_free()
	var robot := RobotParty.party[_selected_slot] as RobotParty.RobotInstance
	for mod in ModuleDB.get_all_modules():
		var btn    := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var reason := _can_equip_module(robot, mod.id)
		var eq: bool = mod.id in robot.equipped_modules
		var summary: String = ModuleDB.modifiers_summary(mod.modifiers) if mod.type == "passive" \
			else "%s (%d EP)" % [mod.skill_id, ModuleDB.effective_skill_cost(mod)]
		btn.text = "%s %s  %s" % [mod.icon, mod.name, summary]
		if eq:
			btn.text += "  ✓"; btn.modulate = Color(0.7,1.0,0.7); btn.disabled = true
		elif reason != "":
			btn.text += "  [%s]" % reason; btn.modulate = Color(0.5,0.5,0.5); btn.disabled = true
		else:
			btn.pressed.connect(_on_module_selected.bind(mod.id))
		equip_popup_items.add_child(btn)
	equip_popup.show()

func _can_equip_module(robot: RobotParty.RobotInstance, module_id: String) -> String:
	if robot.equipped_modules.size() >= 3: return "slots llenos"
	var mod = ModuleDB.get_module(module_id)
	if mod == null: return "desconocido"
	if mod.type == "active":
		for mid in robot.equipped_modules:
			var em = ModuleDB.get_module(mid)
			if em and em.type == "active": return "ya 1 activo"
	if mod.stat_slot != "none":
		for mid in robot.equipped_modules:
			var em = ModuleDB.get_module(mid)
			if em and em.stat_slot != "none": return "ya 1 de stat"
	return ""

func _on_module_selected(module_id: String) -> void:
	_hide_popup()
	RobotParty.equip_module_on_robot(_selected_slot, module_id)

# ─── Popup intercambio de ataque ─────────────────────────────────────────────

func _open_move_swap_popup(robot_slot: int, move_slot: int) -> void:
	_popup_mode         = "move_swap"
	_pending_move_slot  = move_slot
	_pending_robot_slot = robot_slot
	equip_popup_title.text = "Elige ataque para el slot %d" % (move_slot + 1)
	for c in equip_popup_items.get_children(): c.queue_free()

	var robot     := RobotParty.party[robot_slot] as RobotParty.RobotInstance
	var available := robot.available_moves()

	if available.is_empty():
		var lbl     := Label.new()
		lbl.text     = "No hay ataques disponibles para intercambiar."
		lbl.modulate = Color(0.6, 0.6, 0.6)
		equip_popup_items.add_child(lbl)
	else:
		for ab_id in available:
			var btn  := Button.new()
			btn.text  = ab_id
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(_on_move_selected.bind(ab_id))
			equip_popup_items.add_child(btn)

	# Opción de dejar el slot vacío (solo si ya tiene un ataque)
	if move_slot < robot.active_moves.size() and not robot.active_moves[move_slot].is_empty():
		var remove_btn      := Button.new()
		remove_btn.text      = "— Dejar vacío —"
		remove_btn.modulate  = Color(1.0, 0.5, 0.5)
		remove_btn.pressed.connect(_on_move_removed.bind(robot_slot, move_slot))
		equip_popup_items.add_child(remove_btn)

	equip_popup.show()

func _on_move_selected(ability_id: String) -> void:
	var rs: int = _pending_robot_slot
	var ms: int = _pending_move_slot
	_hide_popup()
	RobotParty.set_active_move(rs, ms, ability_id)

func _on_move_removed(robot_slot: int, move_slot: int) -> void:
	_hide_popup()
	var robot := RobotParty.party[robot_slot] as RobotParty.RobotInstance
	if move_slot < robot.active_moves.size() and not robot.active_moves[move_slot].is_empty():
		RobotParty.remove_active_move(robot_slot, robot.active_moves[move_slot])

# ─── Popup info de habilidad ──────────────────────────────────────────────────

func _open_move_info_popup(ability_id: String) -> void:
	_popup_mode = "move_info"
	for c in equip_popup_items.get_children(): c.queue_free()

	equip_popup_title.text = ability_id

	var rows: Array = []   # [[clave, valor], ...]

	if get_node_or_null("/root/AbilityDB") != null:
		var ab = AbilityDB.get_ability(ability_id)
		if ab:
			equip_popup_title.text = ab.get("name")
			if ab.get("power")  > 0:  rows.append(["Potencia",  str(ab.power)])
			if ab.get("accuracy")  > 0:  rows.append(["Precisión", "%d%%" % ab.accuracy])
			if ab.get("ep_cost")  > 0:  rows.append(["Coste EP",  str(ab.ep_cost)])
			if ab.get("effect") != "": rows.append(["Efecto",    ab.effect])
		else:
			rows.append(["", "No encontrado en AbilityDB."])
	else:
		rows.append(["", "AbilityDB no implementado aún."])

	for row in rows:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size   = Vector2(360, 0)  # ← añadir esto

		if row[0] != "":
			var key_lbl := Label.new()
			key_lbl.text = row[0] + ":"
			key_lbl.add_theme_font_size_override("font_size", 12)
			key_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			key_lbl.custom_minimum_size = Vector2(90, 0)  # ← un poco más ancho
			key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # ← no expandir la clave
			hbox.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = row[1]
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(val_lbl)
		
		equip_popup_items.add_child(hbox)
	equip_popup.show()

# ─── Popup helpers ────────────────────────────────────────────────────────────

func _hide_popup() -> void:
	equip_popup.hide()
	_popup_mode         = ""
	_pending_move_slot  = -1
	_pending_robot_slot = -1

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible: return
	if equip_popup.visible:
		if event.is_action_pressed("ui_cancel"): _hide_popup()
		return
	if event.is_action_pressed("ui_cancel"):  _close()
	elif event.is_action_pressed("ui_up"):    _select_slot(max(_selected_slot - 1, 0))
	elif event.is_action_pressed("ui_down"):  _select_slot(min(_selected_slot + 1, RobotParty.party.size() - 1))

# ─── Close ────────────────────────────────────────────────────────────────────

func _close() -> void:
	if anim_player and anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	closed.emit()
