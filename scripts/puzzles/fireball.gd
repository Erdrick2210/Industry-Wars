extends Area2D

var fall_speed = 300.0

func _process(delta):
	position.y += fall_speed * delta

# Connect the "screen_exited" signal from the VisibleOnScreenNotifier2D to this function!
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Deletes the fireball if it falls off-screen
