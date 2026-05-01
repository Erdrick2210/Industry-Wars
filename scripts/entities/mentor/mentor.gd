extends CharacterBody2D

const SPEED = 50.0
@export var MentoraAnimation : AnimatedSprite2D
var target_player : Node2D = null
var is_moving : bool = false

func _ready() -> void:

	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
	
	await get_tree().create_timer(3.0).timeout
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	
	MentoraAnimation.play("idle_down")
	await get_tree().create_timer(1.0).timeout
	
	is_moving = true
	velocity.y = SPEED
	MentoraAnimation.play("run_down")
	await get_tree().create_timer(4.0).timeout
	
	is_moving = false
	velocity = Vector2.ZERO
	MentoraAnimation.play("idle_down")

func _process(_delta: float) -> void:
	if is_moving:
		move_and_slide()
		return
	if target_player:
		var direction = (target_player.global_position - global_position)
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				MentoraAnimation.play("idle_right")
			else:
				MentoraAnimation.play("idle_left")
		else:
			if direction.y > 0:
				MentoraAnimation.play("idle_down")
			else:
				MentoraAnimation.play("idle_up")
	else:
		MentoraAnimation.play("idle_down")

# --- SEÑALES ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = null
