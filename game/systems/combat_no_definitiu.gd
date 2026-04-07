extends Node

# Estats del combat per al State Machine
enum CombatState { START, DETERMINE_TURN, PLAYER_TURN, ENEMY_TURN, END_BATTLE }
var current_state = CombatState.START

# Variables pels robots (fent servir diccionaris amb les dades del teu GDD al Nivell 1)
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

func _ready():
	print("--- Iniciant Duelo en Industry Wars ---")
	setup_combat()

func setup_combat():
	current_state = CombatState.DETERMINE_TURN
	process_state()

func process_state():
	match current_state:
		CombatState.DETERMINE_TURN:
			compare_velocidad()
		CombatState.PLAYER_TURN:
			prompt_player_action()
		CombatState.ENEMY_TURN:
			execute_enemy_ai()
		CombatState.END_BATTLE:
			print("El combat ha acabat. Tornant al Overworld...")

func compare_velocidad():
	print("Calculant l'ordre de torn basat en la Velocitat...")
	# Ordre de torn: Basat en estadística de Velocidad
	if player_robot["velocidad"] >= enemy_robot["velocidad"]:
		current_state = CombatState.PLAYER_TURN
	else:
		current_state = CombatState.ENEMY_TURN
	process_state()

func prompt_player_action():
	print("Torn del jugador! Què farà el robot? (Esperant input de la UI)")
	# El codi s'atura aquí i espera que el jugador premi un botó

# --- FUNCIONS CONNECTADES A LA INTERFÍCIE (UI) ---
# Aquestes funcions s'han de connectar al senyal "pressed()" dels teus botons a Godot

func _on_boton_atacar_pressed():
	if current_state == CombatState.PLAYER_TURN:
		# Exemple d'atac bàsic: Impacto Industrial (Potència 60)
		realizar_ataque(player_robot, enemy_robot, 60) 
		finalizar_turno()

func _on_boton_bolsa_pressed():
	if current_state == CombatState.PLAYER_TURN:
		print("Obrint l'inventari per buscar recambis o cargadors...")
		# Aquí aniria la lògica per restaurar HP o EP
		# finalizar_turno() # Descomentar quan s'utilitzi un objecte

func _on_boton_robot_pressed():
	if current_state == CombatState.PLAYER_TURN:
		print("Mostrant les estadístiques i l'estat dels mòduls...")
		# Això normalment no gasta el torn, només mostra informació

func _on_boton_rendirse_pressed():
	if current_state == CombatState.PLAYER_TURN:
		print("T'has rendit. Abandonant el combat...")
		current_state = CombatState.END_BATTLE
		process_state()

# --- LÒGICA DE COMBAT ---

func realizar_ataque(atacant, defensor, potencia):
	print(atacant["name"] + " ataca " + defensor["name"] + " amb potència " + str(potencia) + "!")
	
	# Fórmula de dany bàsica que utilitza l'Ataque i la Defensa
	var dany = (atacant["ataque"] * potencia / 100.0) - (defensor["defensa"] * 0.1)
	dany = max(1, round(dany)) # Ens assegurem de fer mínim 1 de dany i arrodonim
	
	defensor["hp"] -= dany
	print("Dany causat: " + str(dany) + ". HP restant del defensor: " + str(defensor["hp"]))
	
	check_win_condition()

func execute_enemy_ai():
	print("Torn de l'enemic!")
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
		print("Has guanyat el duel! S'ha rebut EXP i peces per craftejar.")
		current_state = CombatState.END_BATTLE
	elif player_robot["hp"] <= 0:
		print("Cortocircuit crític... Has perdut el combat.")
		current_state = CombatState.END_BATTLE
