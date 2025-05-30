# death_screen.gd - VERSIONE CORRETTA
extends CanvasLayer  # CAMBIATO: Usa CanvasLayer invece di Control per seguire la camera

# --- REFERENCES ---
@onready var score_label = $Control/VBoxContainer/ScoreLabel
@onready var restart_button = $Control/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $Control/VBoxContainer/ButtonContainer/QuitButton
@onready var background = $Control/Background
@onready var control_container = $Control  # Riferimento al nodo Control principale

var game_manager: Node

func _ready():
	# Inizialmente nascosta
	visible = false
	
	# Assicurati che il CanvasLayer sia sopra tutto
	layer = 100
	
	# IMPORTANTE: Imposta il process mode per funzionare anche in pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connetti i bottoni
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
		# Assicurati che anche il bottone funzioni in pausa
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		# Assicurati che anche il bottone funzioni in pausa
		quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Imposta anche il control container per funzionare in pausa
	if control_container:
		control_container.process_mode = Node.PROCESS_MODE_ALWAYS
		control_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Trova il GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	# Connetti al segnale di morte del player se il GameManager esiste
	if game_manager:
		game_manager.player_died.connect(show_death_screen)

func show_death_screen():
	print("Mostrando schermata di morte")  # Debug
	
	# Mostra il punteggio finale
	var final_score = game_manager.get_current_score() if game_manager else 0
	if score_label:
		score_label.text = "Final Score: " + str(final_score)
	
	# Mostra la schermata
	visible = true
	
	# Pausa il gioco
	get_tree().paused = true
	
	# Assicurati che i bottoni siano focusabili
	if restart_button:
		restart_button.grab_focus()

func hide_death_screen():
	print("Nascondendo schermata di morte")  # Debug
	visible = false
	get_tree().paused = false

func _on_restart_pressed():
	print("Restart premuto")  # Debug
	
	# Prima togli la pausa
	get_tree().paused = false
	
	# Nascondi la schermata
	visible = false
	
	# Reset del GameManager
	if game_manager:
		game_manager.reset_game()
	
	# Ricarica la scena principale
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quit premuto")  # Debug
	
	# Prima togli la pausa
	get_tree().paused = false
	
	# Chiudi il gioco
	get_tree().quit()

# Gestisce l'input per evitare che i controlli del gioco funzionino quando la schermata è attiva
func _input(event):
	if visible and event is InputEvent:
		# Accetta solo input dei bottoni quando la schermata è visibile
		if event is InputEventKey or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()

# Funzione per test (puoi rimuoverla in produzione)
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and visible:
		_on_restart_pressed()
	elif event.is_action_pressed("ui_cancel") and visible:
		_on_quit_pressed()
