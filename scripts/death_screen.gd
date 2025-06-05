# death_screen.gd - SOLUZIONE SEMPLIFICATA E FUNZIONANTE
extends CanvasLayer

# --- REFERENCES ---
@onready var score_label = $Control/VBoxContainer/ScoreLabel
@onready var restart_button = $Control/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $Control/VBoxContainer/ButtonContainer/QuitButton

var game_manager: Node

func _ready():
	print("DeathScreen _ready() chiamato")
	
	# Configurazione iniziale
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup immediato
	_setup_everything()

func _setup_everything():
	print("Setup completo death screen...")
	
	# Trova GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if game_manager:
		if not game_manager.player_died.is_connected(show_death_screen):
			game_manager.player_died.connect(show_death_screen)
		print("GameManager connesso")
	
	# Setup pulsanti con connessione diretta
	if restart_button:
		# Assicurati che funzioni in pausa
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Connetti il segnale se non già connesso
		if not restart_button.pressed.is_connected(_on_restart_pressed):
			restart_button.pressed.connect(_on_restart_pressed)
		print("RestartButton configurato")
	
	if quit_button:
		# Assicurati che funzioni in pausa
		quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Connetti il segnale se non già connesso
		if not quit_button.pressed.is_connected(_on_quit_pressed):
			quit_button.pressed.connect(_on_quit_pressed)
		print("QuitButton configurato")

func show_death_screen():
	print("=== MOSTRANDO DEATH SCREEN ===")
	
	# Imposta punteggio
	var final_score = game_manager.get_current_score() if game_manager else 0
	if score_label:
		score_label.text = "Final Score: " + str(final_score)
	
	# Rendi visibile
	visible = true
	
	# Pausa il gioco
	get_tree().paused = true
	
	# Focus sul pulsante restart
	if restart_button:
		restart_button.grab_focus()
	
	print("Death screen mostrata e gioco in pausa")

func _on_restart_pressed():
	print("=== RESTART PRESSED ===")
	_restart_game()

func _on_quit_pressed():
	print("=== QUIT PRESSED ===")
	_quit_game()

func _restart_game():
	print("Restarting game...")
	
	# Prima cosa: togli la pausa
	get_tree().paused = false
	
	# Nascondi schermata
	visible = false
	
	# Reset game manager
	if game_manager:
		game_manager.reset_game()
	
	# Ricarica scena
	get_tree().reload_current_scene()

func _quit_game():
	print("Quitting game...")
	
	# Togli pausa
	get_tree().paused = false
	
	# Chiudi gioco
	get_tree().quit()

# Input handler semplificato per tastiera
func _unhandled_input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		print("Enter premuto")
		_restart_game()
	elif event.is_action_pressed("ui_cancel"):
		print("Esc premuto") 
		_quit_game()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("R premuto")
				_restart_game()
			KEY_Q:
				print("Q premuto")
				_quit_game()
