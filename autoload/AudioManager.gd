extends Node

@onready var music_player = $MusicPlayer

@onready var sfx_players = [
	$SFXPlayer,
	$SFXPlayer2,
	$SFXPlayer3
]

const UI_CLICK_PATH = "res://assets/audio/sfx/select.WAV"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func(): play_sfx(UI_CLICK_PATH))

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
