class_name InteractableNPC
extends CharacterBody2D

@export var animation_sprite: AnimatedSprite2D
@export var speed : float
@export var look_distance: float = 150.0

var target_player: Node2D = null
var is_blocked_look: bool = false

func _ready() -> void:
	var detection_area = _find_detection_area()
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

func _find_detection_area() -> Area2D:
	for child in get_children():
		if child is Area2D:
			return child
	return null

func _physics_process(_delta: float) -> void:
	if not is_blocked_look:
		_update_look_direction()

func _update_look_direction() -> void:
	
	if target_player == null:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			target_player = players[0]
	
	if target_player and animation_sprite:
		var distance = global_position.distance_to(target_player.global_position)
		if distance <= look_distance:
			var diff = target_player.global_position - global_position
			if abs(diff.x) > abs(diff.y):
				animation_sprite.play("idle_right" if diff.x > 0 else "idle_left")
			else:
				animation_sprite.play("idle_down" if diff.y > 0 else "idle_up")
		else:
			animation_sprite.play("idle_down")

func interact() -> void:
	pass #Every son makes his own

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = null
