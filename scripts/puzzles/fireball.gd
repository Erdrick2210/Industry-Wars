extends Area2D

var fall_speed: float = 300.0

func _process(delta):
	position.y += fall_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	# Tell the parent node (MinigameLevel) that this one was missed
	get_parent().fireball_missed()
	
	# Destroy the fireball
	queue_free()
