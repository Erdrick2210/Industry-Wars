extends Node

@onready var music_player = $MusicPlayer

@onready var sfx_players = [
	$SFXPlayer,
	$SFXPlayer2,
	$SFXPlayer3
]

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
