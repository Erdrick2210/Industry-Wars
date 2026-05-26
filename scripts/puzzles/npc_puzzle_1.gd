extends InteractableNPC

const MINIGAME_SCENE = preload("res://game/scenes/puzzle1/minigame_puzzle1.tscn")
@onready var area_int : Area2D = $Area2D
@onready var damaged_lab : TileMapLayer = $"../DamagedLab"
@export var switch_time: float = 1.5

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "npc_puzzle1_thanks"

var direction: int = 1
var timer: float = 0.0

func _ready() -> void:
	if GameEvents.lab_repaired:
		if damaged_lab:
			damaged_lab.visible = false
		if area_int and area_int.has_node("CollisionShape2D"):
			area_int.get_node("CollisionShape2D").disabled = true
			
	if not GameEvents.oldman_is_running:
		velocity = Vector2.ZERO
		if animation_sprite:
			animation_sprite.play("idle_down")

func _physics_process(delta):
	if not GameEvents.oldman_is_running:
		velocity.x = 0
		move_and_slide()
		return
		
	timer += delta
	
	if timer >= switch_time or is_on_wall():
		direction *= -1
		timer = 0.0
		
	velocity.x = direction * speed
	
	if animation_sprite:
		if direction == 1:
			animation_sprite.play("run_right")
		else:
			animation_sprite.play("run_left")
		
	move_and_slide()

func interact() -> void:
	GameEvents.oldman_is_running = false
			
	var minigame = MINIGAME_SCENE.instantiate()
	print("Starting minigame!")
	get_tree().root.add_child(minigame)
	
	var cam_minigame = minigame.get_node("Camera2D")
	if cam_minigame:
		cam_minigame.make_current()
	
	if owner:
		owner.visible = false
		owner.process_mode = Node.PROCESS_MODE_DISABLED
	
	minigame.game_over.connect(_on_minigame_ended.bind(minigame))

func _on_minigame_ended(win: bool, minigame_node: Node):
	minigame_node.queue_free()
	
	if win:
		print("Minigame won!")
		repair_lab()
		GameEvents.oldman_is_running = false
		Inventory.add_item("gyro")
		if animation_sprite:
			animation_sprite.play("idle_down")
			
		if dialogue_resource:
			if target_player and target_player.has_method("set_frozen"):
				target_player.set_frozen(true)
		
			await DialogueManager.show_dialogue_balloon(dialogue_resource, "npc_puzzle1_thanks")
		
			if target_player and target_player.has_method("set_frozen"):
				target_player.set_frozen(false)
	else:
		print("Minigame failed!")
		GameEvents.oldman_is_running = true
	
	if owner:
		owner.visible = true
		owner.process_mode = Node.PROCESS_MODE_INHERIT
		
	if win and area_int and area_int.has_node("CollisionShape2D"):
		area_int.get_node("CollisionShape2D").set_deferred("disabled", true)
	
func repair_lab():
	if damaged_lab:
		damaged_lab.visible = false
	GameEvents.lab_repaired = true
