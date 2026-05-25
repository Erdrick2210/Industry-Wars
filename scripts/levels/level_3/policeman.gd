extends CharacterBody2D

@export var freeze_time: float = 2.0

@onready var target_player : CharacterBody2D = $"../Player"
@onready var trigger_area: Area2D = $TriggerPoliceman
@onready var vending_node: Node2D = $"../Vending_Machine"
@onready var barricade : TileMapLayer = $"../Walls/Barricade"
var vending_area: Area2D = null
var animation_sprite: AnimatedSprite2D = null

func _ready():
	if vending_node:
		for child in vending_node.get_children():
			if child is Area2D:
				vending_area = child
				break
	for child in get_children():
		if child is AnimatedSprite2D:
			animation_sprite = child
			break

func retire_guard() -> void:
	if not target_player: return
	
	var target_pos: Vector2 = global_position + Vector2(-60, 0)
	
	if animation_sprite:
		if target_pos.x > global_position.x:
			animation_sprite.play("run_right")
		else:
			animation_sprite.play("run_left")
			
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	
	velocity = Vector2.ZERO
	if animation_sprite:
		animation_sprite.play("idle_right")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("set_frozen"):
			body.set_frozen(true)
			
		await get_tree().create_timer(freeze_time).timeout
		
		if vending_area.has_bought():
			barricade.visible = false
			barricade.collision_enabled = false
			trigger_area.monitoring = false
			trigger_area.monitorable = false
			retire_guard()
			
		if is_instance_valid(body) and body.has_method("set_frozen"):
			body.set_frozen(false)
