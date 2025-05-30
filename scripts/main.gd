# main.gd - VERSIONE CORRETTA
extends Node

var wave_manager: Node
var game_manager: Node

func _ready():
	print("Main scene ready")  # Debug
	_setup_managers()
	_setup_ui()

func _setup_managers():
	# Trova il GameManager (che dovrebbe essere un autoload)
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if !game_manager:
		print("ERRORE: GameManager non trovato come autoload!")
	
	# Altri manager se necessari
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)

func _setup_ui():
	# Aggiungi l'HUD del punteggio
	var score_hud = preload("res://scenes/UI/score_hud.tscn").instantiate()
	add_child(score_hud)
	
	# Aggiungi la schermata di morte COME ULTIMO ELEMENTO
	# per assicurarsi che sia sopra tutto
	var death_screen = preload("res://scenes/ui/death_screen.tscn").instantiate()
	add_child(death_screen)
	
	print("UI configurata")  # Debug

# Funzione chiamata quando la scena è completamente caricata
func _notification(what):
	if what == NOTIFICATION_READY:
		# Assicurati che il GameManager sia inizializzato
		call_deferred("_delayed_setup")

func _delayed_setup():
	if game_manager:
		print("Configurazione ritardata completata")
	else:
		print("GameManager ancora non disponibile")
