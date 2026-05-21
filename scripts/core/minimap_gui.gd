extends Control

@onready var container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var map_camera = $SubViewportContainer/SubViewport/MapCamera
@onready var player_icon = $PlayerIcon
@onready var _bg_panel = $Panel 

var player: Node2D = null
var is_interior: bool = false
var is_expanded: bool = false

var size_mini : Vector2 = Vector2(246, 186)
var zoom_mini : Vector2 = Vector2(0.2, 0.2)
var zoom_full : Vector2 = Vector2(0.6, 0.6)

var map_center_offset: Vector2 = Vector2.ZERO
var nav_speed: float = 400.0

func _ready() -> void:
	await get_tree().process_frame
	
	if map_camera == null:
		return
		
	viewport.world_2d = get_tree().root.get_world_2d()
	map_camera.visibility_layer = 1
	
	_check_current_level_zone()
	_update_view_mode()

func _process(delta: float) -> void:
	if is_interior:
		return
		
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		return
	
	if not is_expanded:
		map_camera.global_position = player.global_position
	else:
		var input_dir = Input.get_vector("left", "right", "up", "down")
		map_center_offset += input_dir * nav_speed * delta
		map_camera.global_position = player.global_position + map_center_offset

	var player_screen_pos = viewport.get_canvas_transform() * player.global_position
	player_icon.position = container.position + player_screen_pos
	
	player_icon.rotation = 0

func _unhandled_input(event: InputEvent) -> void:
	if is_interior:
		return
		
	if event.is_action_pressed("map_toggle"):
		toggle_map_mode()

func toggle_map_mode() -> void:
	is_expanded = !is_expanded
	_update_view_mode()

func _update_view_mode() -> void:
	if is_expanded:
		if _bg_panel:
			_bg_panel.visible = false
			
		if player_icon:
			player_icon.visible = false
			
		var screen_size = Vector2(get_viewport_rect().size)
		
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		position = Vector2.ZERO
		container.position = Vector2.ZERO
		
		container.size = screen_size
		viewport.size = screen_size
		map_camera.zoom = zoom_full
		map_center_offset = Vector2.ZERO
		
		# CONGELAR: Solo actuamos al pasar a pantalla completa
		if player and player.has_method("set_frozen"):
			player.set_frozen(true)
	else:
		if _bg_panel:
			_bg_panel.visible = true
			_bg_panel.size = size_mini + Vector2(6, 6)
			_bg_panel.position = Vector2(-3, -3)
			
		if player_icon:
			player_icon.visible = true
			
		container.size = size_mini
		viewport.size = size_mini
		map_camera.zoom = zoom_mini
		
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		position = Vector2(20, 20)
		container.position = Vector2.ZERO
		
		if player and player.has_method("set_frozen"):
			player.set_frozen(false)

func _check_current_level_zone() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		var raw_val = current_scene.get("is_interior")
		var level_is_interior: bool = raw_val if raw_val != null else true
		
		if current_scene.get("_instantiated_level") != null:
			var main_level = current_scene._instantiated_level
			var cached_val = main_level.get("is_interior")
			level_is_interior = cached_val if cached_val != null else true
		
		is_interior = level_is_interior
		visible = !level_is_interior
		
func set_map_limits(left: int, top: int, right: int, bottom: int) -> void:
	if is_instance_valid(map_camera):
		map_camera.limit_left = left
		map_camera.limit_top = top
		map_camera.limit_right = right
		map_camera.limit_bottom = bottom
