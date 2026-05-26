extends Node

@onready var music_player = $MusicPlayer

@onready var sfx_players = [
	$SFXPlayer,
	$SFXPlayer2,
	$SFXPlayer3
]

const SAVE_PATH := "user://audio_settings.json"
const UI_CLICK_PATH = "res://assets/audio/sfx/select.WAV"

# ─────────────────────────────
# VOLUMES (0.0 - 1.0)
# ─────────────────────────────

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0

func _ready():
	_load_settings()
	_apply_volumes()
  
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	
func _apply_volumes():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	
func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()

func set_music_volume(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()

func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()
	
func _save_settings():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"master": master_volume,
			"music": music_volume,
			"sfx": sfx_volume
		}))

func _load_settings():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if typeof(data) != TYPE_DICTIONARY:
		return

	master_volume = data.get("master", 1.0)
	music_volume = data.get("music", 1.0)
	sfx_volume = data.get("sfx", 1.0)

func play_music(path: String):
	var stream = load(path)

	if music_player.stream == stream:
		return

	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(path: String):
	var stream = load(path)

	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	  
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func(): play_sfx(UI_CLICK_PATH))
