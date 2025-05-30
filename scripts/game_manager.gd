# game_manager.gd - VERSIONE CORRETTA
extends Node
# Aggiungi all'inizio del file, dopo extends Node:
func _init():
	print("GameManager autoload inizializzato")
	name = "GameManager"  # Assicura il nome corretto

# --- SPAWN SETTINGS ---
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5  # Ridotto da 3.0 a 1.5 secondi (spawn più frequente)
@export var min_spawn_distance: float = 800.0  # Ridotto da 1200.0 (più vicino al player)
@export var max_spawn_distance: float = 1400.0  # Ridotto da 1800.0 (range più stretto)
@export var spawn_margin: float = 150.0  # Ridotto da 200.0

# --- SCORE SYSTEM ---
var current_score: int = 0
var points_per_enemy: int = 100

# --- GAME STATE ---
var game_active: bool = false

# --- REFERENCES ---
var spawn_timer: Timer
var player: CharacterBody2D
var score_label: Label

# --- SIGNALS ---
signal score_changed(new_score: int)
signal player_died

func _ready():
	print("GameManager ready (Autoload)")
	
	# Carica la scena del nemico con gestione errori
	if not enemy_scene:
		var enemy_path = "res://scenes/enemy_fly.tscn"
		if ResourceLoader.exists(enemy_path):
			enemy_scene = load(enemy_path)
			print("Enemy scene caricata: ", enemy_scene != null)
		else:
			print("ERRORE: File enemy_fly.tscn non trovato in ", enemy_path)
	
	_setup_spawn_timer()
	_connect_signals()
	call_deferred("_delayed_start")

func _delayed_start():
	print("GameManager _delayed_start chiamato")
	# Verifica che tutto sia pronto
	if get_tree() and get_tree().current_scene:
		print("Scena corrente disponibile: ", get_tree().current_scene.name)
	else:
		print("ERRORE: Scena corrente non disponibile")

func _setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.autostart = false
	add_child(spawn_timer)

func _connect_signals():
	score_changed.connect(_on_score_changed)

func start_game():
	print("Avviando il gioco")
	game_active = true
	current_score = 0
	score_changed.emit(current_score)
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERRORE: Player non trovato nel gruppo 'player'!")
		return
	
	print("Player trovato: ", player.name)
	
	# Validazione più robusta del timer
	if spawn_timer and is_instance_valid(spawn_timer):
		if spawn_timer.is_stopped():
			spawn_timer.start()
			print("Timer di spawn avviato")
		else:
			print("Timer già attivo")
	else:
		print("ERRORE: Timer di spawn non valido!")
		_setup_spawn_timer()  # Ricrea il timer
		if spawn_timer:
			spawn_timer.start()

func stop_game():
	print("Fermando il gioco")
	game_active = false
	if spawn_timer:
		spawn_timer.stop()

func _spawn_enemy():
	if not game_active:
		print("Game non attivo, saltando spawn")
		return
		
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("Player non trovato per spawn nemico")
			return
	
	if not enemy_scene:
		print("Enemy scene non disponibile")
		return
	
	var spawn_position = _get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		print("Posizione spawn non valida")
		return
	
	var enemy = enemy_scene.instantiate()
	if not enemy:
		print("Errore nell'istanziare il nemico")
		return
		
	enemy.global_position = spawn_position
	
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.call_deferred("add_child", enemy)
		print("Nemico spawnato in posizione: ", spawn_position)
	else:
		print("ERRORE: Scena corrente non trovata per spawn")
		enemy.queue_free()

func _get_random_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var player_pos = player.global_position
	var attempts = 20
	
	for i in attempts:
		var angle = randf() * 2 * PI
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		
		if _is_valid_spawn_position(spawn_pos):
			return spawn_pos
	
	# Fallback: spawn in una posizione minima
	return player_pos + Vector2(min_spawn_distance, 0).rotated(randf() * 2 * PI)

func _is_valid_spawn_position(pos: Vector2) -> bool:
	# Versione semplificata per evitare problemi nell'export
	if not player:
		return false
	
	var distance_to_player = pos.distance_to(player.global_position)
	return distance_to_player >= min_spawn_distance and distance_to_player <= max_spawn_distance

func add_score(points: int):
	if not game_active:
		return
	current_score += points
	score_changed.emit(current_score)

func get_current_score() -> int:
	return current_score

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: " + str(new_score)

func on_player_died():
	print("Player morto - fermando il gioco")
	stop_game()
	
	# Emetti il segnale immediatamente
	player_died.emit()
	print("Segnale player_died emesso")

func reset_game():
	print("Resettando il gioco")
	stop_game()
	
	current_score = 0
	score_changed.emit(current_score)
	
	# Rimuovi tutti i nemici esistenti
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Rimuovi tutti i proiettili
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	# Rimuovi tutti i power-up
	var powerups = get_tree().get_nodes_in_group("powerups")
	for powerup in powerups:
		if is_instance_valid(powerup):
			powerup.queue_free()

func set_score_label(label: Label):
	score_label = label
	if score_label:
		score_label.text = "Score: " + str(current_score)
