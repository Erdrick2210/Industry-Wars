extends Interactable

const MINIGAME_SCENE = preload("res://game/scenes/puzzle1/minigame_puzzle1.tscn")
@onready var area_int : Area2D = $Area2D
@onready var damaged_lab : TileMapLayer = $"../DamagedLab"
@export var speed: float = 200.0
@export var switch_time: float = 1.5

var direction: int = 1
var timer: float = 0.0
var is_running: bool = true  # <--- NUEVA VARIABLE

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# Si no debe correr, detenemos la velocidad y salimos de la función
	if not is_running:
		velocity.x = 0
		move_and_slide()
		return

	timer += delta
	
	if timer >= switch_time or is_on_wall():
		direction *= -1
		timer = 0.0
		
	velocity.x = direction * speed
	
	if direction == 1:
		anim.play("run_right")
	else:
		anim.play("run_left")
		
	move_and_slide()

func interact() -> void:
	is_running = false # <--- SE DETIENE AL HABLAR
	
	var minigame = MINIGAME_SCENE.instantiate()
	print("¡Iniciando minijuego!")
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
		print("¡El NPC dice: Bien hecho, superaste el puzzle!")
		repair_lab()
		is_running = false # <--- SE QUEDA QUIETO PARA SIEMPRE
		anim.play("idle_down")  # <--- Asegúrate de tener una animación llamada "idle"
	else:
		print("¡El NPC dice: Has fallado, vuelve a intentarlo!")
		is_running = true  # <--- VUELVE A CORRER SI FALLAS
	
	if owner:
		owner.visible = true
		owner.process_mode = Node.PROCESS_MODE_INHERIT
	
func repair_lab():
	damaged_lab.visible = false
