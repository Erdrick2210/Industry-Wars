extends InteractableNPC

const MINIGAME_SCENE = preload("res://game/scenes/puzzle3/puzzle3_level.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if animation_sprite:
		animation_sprite.play("idle_down")

func interact() -> void:
	var minigame = MINIGAME_SCENE.instantiate()
	get_tree().root.add_child(minigame)
	minigame.game_over.connect(_on_minigame_ended.bind(minigame))
	
	if owner:
		owner.visible = false
		owner.process_mode = Node.PROCESS_MODE_DISABLED

func _on_minigame_ended(_win: bool, minigame_node: Node) -> void:
	if is_instance_valid(minigame_node):
		minigame_node.queue_free()
	if owner:
		owner.visible = true
		owner.process_mode = Node.PROCESS_MODE_INHERIT
