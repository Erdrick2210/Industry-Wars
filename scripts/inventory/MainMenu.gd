## MainMenu.gd
## Script del menú principal (Guardar / Robots / Taller / Bolsa / Coleccionables).
## Adjuntar a res://scenes/MainMenu.tscn

extends Control

# ─── Scene refs ───────────────────────────────────────────────────────────────

@onready var menu_list:      VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/MenuList
@onready var cursor_sprite:  Sprite2D      = $CursorSprite   # bagSel.png
@onready var subtitle_label: Label         = $PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel

# Sub-scenes to open
const BAG_SCENE    = preload("res://game/scenes/inventory/BagMenu.tscn")
const TALLER_SCENE = preload("res://game/scenes/inventory/TallerMenu.tscn")
const ROBOT_SCENE = preload("res://game/scenes/inventory/RobotMenu.tscn")
const OPTIONS_SCENE = preload("res://game/scenes/options_menu.tscn")
# ─── Menu entries ─────────────────────────────────────────────────────────────

const ENTRIES = [
	{"label": "Guardar",        "subtitle": "Guarda el progreso de tu partida.",         "scene": ""},
	{"label": "Robots",         "subtitle": "Gestiona tu equipo de robots.",              "scene": "ROBOT"},
	{"label": "Taller",         "subtitle": "Construye módulos con componentes.",         "scene": "TALLER"},
	{"label": "Bolsa",          "subtitle": "Revisa y usa los objetos que llevas.",       "scene": "BAG"},
	{"label": "Configuración",  "subtitle": "Ajusta el volumen y otras opciones.",        "scene": "CONFIG"}
]

var _selected_index := 0
var _buttons: Array = []

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_menu()
	_refresh_cursor()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO

# ─── Build UI ─────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var style_clear := StyleBoxFlat.new()
	style_clear.bg_color       = Color(0, 0, 0, 0)  # transparente total
	style_clear.border_width_top    = 0
	style_clear.border_width_bottom = 0
	style_clear.border_width_left   = 0
	style_clear.border_width_right  = 0
	style_clear.draw_center    = true

	for entry in ENTRIES:
		var btn := Button.new()
		btn.text                = entry["label"]
		btn.focus_mode          = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(160, 32)
		btn.flat                = true  # <-- esto es clave, desactiva el dibujo del tema

		btn.add_theme_stylebox_override("normal",   style_clear)
		btn.add_theme_stylebox_override("hover",    style_clear)
		btn.add_theme_stylebox_override("pressed",  style_clear)
		btn.add_theme_stylebox_override("focus",    style_clear)
		btn.add_theme_stylebox_override("disabled", style_clear)

		btn.add_theme_color_override("font_color",         Color.WHITE)
		btn.add_theme_color_override("font_hover_color",   Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_color_override("font_focus_color",   Color.WHITE)

		btn.pressed.connect(_on_entry_pressed.bind(ENTRIES.find(entry)))
		btn.focus_entered.connect(_on_entry_focused.bind(ENTRIES.find(entry)))
		menu_list.add_child(btn)
		_buttons.append(btn)

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_move_cursor(0)
	elif event.is_action_pressed("ui_up"):
		_move_cursor(0)
	elif event.is_action_pressed("ui_accept"):
		_on_entry_pressed(_selected_index)
	elif event.is_action_pressed("ui_cancel"):
		# Close menu — emit signal or call parent
		hide()

func _move_cursor(dir: int) -> void:
	_selected_index = wrapi(_selected_index + dir, 0, _buttons.size())
	_buttons[_selected_index].grab_focus()
	_refresh_cursor()

func _refresh_cursor() -> void:
	if _buttons.is_empty():
		return
	var btn: Button = _buttons[_selected_index] as Button
	var pos  := btn.global_position
	cursor_sprite.global_position = Vector2(pos.x - 5, pos.y - 5)
	subtitle_label.text = ENTRIES[_selected_index]["subtitle"]

# ─── Handlers ─────────────────────────────────────────────────────────────────

func _on_entry_focused(idx: int) -> void:
	_selected_index = idx
	_refresh_cursor()

func _on_entry_pressed(idx: int) -> void:
	match ENTRIES[idx]["scene"]:
		"BAG":
			var bag := BAG_SCENE.instantiate()
			_open_submenu(bag)
		"TALLER":
			var taller := TALLER_SCENE.instantiate()
			_open_submenu(taller)
		"ROBOT":
			var robots := ROBOT_SCENE.instantiate()
			_open_submenu(robots)
		"CONFIG":
			var options := OPTIONS_SCENE.instantiate()
			_open_submenu(options)
		"":
			print("Menú '%s' no implementado aún." % ENTRIES[idx]["label"])

func _open_submenu(submenu: Control) -> void:
	# Reutiliza el mismo CanvasLayer que ya existe en el padre
	var canvas := get_parent()  # el CanvasLayer creado desde la escena principal
	canvas.add_child(submenu)
	submenu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	submenu.closed.connect(func(): submenu.queue_free())
