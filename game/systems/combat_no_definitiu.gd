extends Node

@onready var combat_log = $CombatLog

# Estats del combat
enum CombatState { START, DETERMINE_TURN, PLAYER_TURN, ENEMY_TURN, END_BATTLE }
var current_state = CombatState.START

# Variables pels robots
var player_robot = {
	"name": "Chasis Asalto",
	"hp": 80,
	"max_hp": 80,
	"ep": 50,
	"ataque": 95,
	"defensa": 55,
	"velocidad": 50
}

var enemy_robot = {
	"name": "Chasis Guardián",
	"hp": 100,
	"max_hp": 100,
	"ep": 50,
	"ataque": 50,
	"defensa": 90,
	"velocidad": 30
}

func log_text(texto: String):
	combat_log.text = ""
	for c in texto:
		combat_log.text += c
		await get_tree().create_timer(0.02).timeout
	combat_log.text += "\n"
	
func clear_log():
	combat_log.text = ""

func _ready():
	log_text("Iniciando duelo...")
	setup_combat()

func setup_combat():
	current_state = CombatState.DETERMINE_TURN
	process_state()

func process_state():
	await get_tree().create_timer(2.0).timeout
	match current_state:
		CombatState.DETERMINE_TURN:
			compare_velocidad()
		CombatState.PLAYER_TURN:
			prompt_player_action()
		CombatState.ENEMY_TURN:
			execute_enemy_ai()
		CombatState.END_BATTLE:
			log_text("El combate ha acabado. Volviendo al overworld...")

func compare_velocidad():
	log_text("Calculando orden de turno basado en la velocidad...")
	# Ordre de torn: Basat en estadística de Velocidad
	if player_robot["velocidad"] >= enemy_robot["velocidad"]:
		current_state = CombatState.PLAYER_TURN
	else:
		current_state = CombatState.ENEMY_TURN
	process_state()

func prompt_player_action():
	log_text("¡Turno del jugador! ¿Què hará el robot?")
	# El codi s'atura aquí i espera que el jugador premi un botó

# --- FUNCIONS CONNECTADES A LA INTERFÍCIE (UI) ---

func _on_fight_pressed():
	if current_state == CombatState.PLAYER_TURN:
		# Exemple d'atac bàsic: Impacto Industrial (Potència 60)
		realizar_ataque(player_robot, enemy_robot, 60) 
		finalizar_turno()

func _on_boton_bolsa_pressed():
	if current_state == CombatState.PLAYER_TURN:
		print("Abriendo el inventario...")
		# Aquí aniria la lògica per restaurar HP o EP
		# finalizar_turno() # Descomentar quan s'utilitzi un objecte

func _on_boton_robot_pressed():
	if current_state == CombatState.PLAYER_TURN:
		print("Mostrando los robots...")
		# Això normalment no gasta el torn, només mostra informació

func _on_boton_rendirse_pressed():
	if current_state == CombatState.PLAYER_TURN:
		log_text("Te has rendido. Abandonando el combate...")
		current_state = CombatState.END_BATTLE
		process_state()

# --- LÒGICA DE COMBAT ---

func realizar_ataque(atacant, defensor, potencia):
	print(atacant["name"] + " ataca " + defensor["name"] + " amb potència " + str(potencia) + "!")
	
	# Fórmula de dany bàsica que utilitza l'Ataque i la Defensa
	var dany = (atacant["ataque"] * potencia / 100.0) - (defensor["defensa"] * 0.1)
	dany = max(1, round(dany)) # Ens assegurem de fer mínim 1 de dany i arrodonim
	
	if defensor["hp"] >= dany:
		defensor["hp"] -= dany
	else:
		dany = defensor["hp"]
		defensor["hp"] = 0
	print("Daño causado: " + str(dany) + ". HP restante del defensor: " + str(defensor["hp"]))
	
	check_win_condition()

func execute_enemy_ai():
	log_text("¡Turno del enemigo!")
	# Intel·ligència artificial molt bàsica: sempre fa un atac estàndard
	realizar_ataque(enemy_robot, player_robot, 50) 
	finalizar_turno()

func finalizar_turno():
	# Si algú ha guanyat durant l'atac, aturem el canvi de torn
	if current_state == CombatState.END_BATTLE:
		return
		
	# Canvi de torn
	if current_state == CombatState.PLAYER_TURN:
		current_state = CombatState.ENEMY_TURN
	else:
		current_state = CombatState.PLAYER_TURN
		
	process_state()

func check_win_condition():
	if enemy_robot["hp"] <= 0:
		log_text("¡Has ganado el combate! Has recibido EXP i piezas.")
		current_state = CombatState.END_BATTLE
	elif player_robot["hp"] <= 0:
		log_text("Has perdido el combate.")
		current_state = CombatState.END_BATTLE
