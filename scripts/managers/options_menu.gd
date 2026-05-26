extends Control

@onready var master_slider = $Panel/VBoxContainer/MasterRow/MasterSlider
@onready var master_value_label = $Panel/VBoxContainer/MasterRow/MasterValue
@onready var music_slider  = $Panel/VBoxContainer/MusicRow/MusicSlider
@onready var music_value_label = $Panel/VBoxContainer/MusicRow/MusicValue
@onready var sfx_slider    = $Panel/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_value_label = $Panel/VBoxContainer/SFXRow/SFXValue
@onready var close_btn     = $Panel/VBoxContainer/CloseButton

signal closed

func _ready():
	# cargar valores actuales
	master_slider.value = AudioManager.master_volume
	master_value_label.text = str(int(master_slider.value * 100)) + "%"
	music_slider.value  = AudioManager.music_volume
	music_value_label.text = str(int(music_slider.value * 100)) + "%"
	sfx_slider.value = AudioManager.sfx_volume
	sfx_value_label.text = str(int(sfx_slider.value * 100)) + "%"

	# conexiones
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	close_btn.pressed.connect(_close)

func _on_master_changed(value: float):
	AudioManager.set_master_volume(value)
	master_value_label.text = str(int(value * 100)) + "%"

func _on_music_changed(value: float):
	AudioManager.set_music_volume(value)
	music_value_label.text = str(int(value * 100)) + "%"

func _on_sfx_changed(value: float):
	AudioManager.set_sfx_volume(value)
	sfx_value_label.text = str(int(value * 100)) + "%"

func _close():
	AudioManager.play_sfx("res://assets/audio/sfx/select.WAV")
	closed.emit()
	queue_free()
