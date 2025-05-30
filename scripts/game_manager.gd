# game_manager.gd - VERSIONE CORRETTA
extends Node

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
	
	# Carica la scena del nemico se non è assegnata
	if not enemy_scene:
		enemy_scene = preload("res://scenes/enemy_fly.tscn")
	
	_setup_spawn_timer()
	_connect_signals()
	
	# Aspetta un frame per permettere alla scena di caricarsi completamente
	call_deferred("_delayed_start")

func _delayed_start():
	# Non iniziare automaticamente - aspetta che il player sia pronto
	pass

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
	
	# Aspetta un momento prima di cercare il player
	await get_tree().process_frame
	
	# Trova il player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERRORE: Player non trovato nel gruppo 'player'!")
		return
	
	print("Player trovato: ", player.name)
	
	if spawn_timer:
		spawn_timer.start()
		print("Timer di spawn avviato")
	
	print("Gioco avviato con successo")

func stop_game():
	print("Fermando il gioco")
	game_active = false
	if spawn_timer:
		spawn_timer.stop()

func _spawn_enemy():
	if not game_active or not is_instance_valid(player) or not enemy_scene:
		print("Impossibile spawnare nemico: game_active=", game_active, ", player_valid=", is_instance_valid(player), ", enemy_scene=", enemy_scene != null)
		return
	
	var spawn_position = _get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		print("Posizione di spawn non valida")
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	# Aggiungi alla scena corrente
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(enemy)
		print("Nemico spawnato in posizione: ", spawn_position)
	else:
		print("ERRORE: Scena corrente non trovata")

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
	var viewport = get_viewport()
	if not viewport:
		return true
		
	var camera = viewport.get_camera_2d()
	if not camera:
		return true
	
	var viewport_rect = viewport.get_visible_rect()
	var camera_pos = camera.global_position
	var screen_size = viewport_rect.size / camera.zoom
	
	var left_bound = camera_pos.x - screen_size.x / 2 - spawn_margin
	var right_bound = camera_pos.x + screen_size.x / 2 + spawn_margin
	var top_bound = camera_pos.y - screen_size.y / 2 - spawn_margin
	var bottom_bound = camera_pos.y + screen_size.y / 2 + spawn_margin
	
	return pos.x < left_bound or pos.x > right_bound or pos.y < top_bound or pos.y > bottom_bound

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
