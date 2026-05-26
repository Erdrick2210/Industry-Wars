extends Control

@onready var scroll = $VBoxContainer/ScrollContainer
@onready var timer = $Timer

func _ready():
	modulate.a = 0

	var tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		1.0
	)

func _on_timer_timeout():
	scroll.scroll_vertical += 1
