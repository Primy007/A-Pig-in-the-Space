# game_manager.gd - VERSIONE CORRETTA
extends Node

# --- SINGLETON PATTERN ---
# Questo script dovrebbe essere un autoload (Singleton)

# --- SPAWN SETTINGS ---
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var min_spawn_distance: float = 1200.0
@export var max_spawn_distance: float = 1800.0
@export var spawn_margin: float = 200.0

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
	print("GameManager ready")  # Debug
	_setup_spawn_timer()
	_connect_signals()

func _setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.autostart = false  # Non iniziare automaticamente
	add_child(spawn_timer)

func _connect_signals():
	score_changed.connect(_on_score_changed)

func start_game():
	print("Avviando il gioco")  # Debug
	game_active = true
	current_score = 0
	score_changed.emit(current_score)
	
	# Trova il player
	player = get_tree().get_first_node_in_group("player")
	if !player:
		print("ERRORE: Player non trovato!")
		return
	
	if spawn_timer:
		spawn_timer.start()
	
	print("Gioco avviato con successo")

func stop_game():
	print("Fermando il gioco")  # Debug
	game_active = false
	if spawn_timer:
		spawn_timer.stop()

func _spawn_enemy():
	if !game_active or !is_instance_valid(player) or !enemy_scene:
		return
	
	var spawn_position = _get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)

func _get_random_spawn_position() -> Vector2:
	if !player:
		return Vector2.ZERO
	
	var player_pos = player.global_position
	var attempts = 20
	
	for i in attempts:
		var angle = randf() * 2 * PI
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		
		if _is_valid_spawn_position(spawn_pos):
			return spawn_pos
	
	return player_pos + Vector2(min_spawn_distance, 0).rotated(randf() * 2 * PI)

func _is_valid_spawn_position(pos: Vector2) -> bool:
	var viewport = get_viewport().get_visible_rect()
	var camera = get_viewport().get_camera_2d()
	
	if !camera:
		return true
	
	var camera_pos = camera.global_position
	var screen_size = viewport.size / camera.zoom
	
	var left_bound = camera_pos.x - screen_size.x / 2 - spawn_margin
	var right_bound = camera_pos.x + screen_size.x / 2 + spawn_margin
	var top_bound = camera_pos.y - screen_size.y / 2 - spawn_margin
	var bottom_bound = camera_pos.y + screen_size.y / 2 + spawn_margin
	
	return pos.x < left_bound or pos.x > right_bound or pos.y < top_bound or pos.y > bottom_bound

func add_score(points: int):
	if !game_active:
		return
	current_score += points
	score_changed.emit(current_score)

func get_current_score() -> int:
	return current_score

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: " + str(new_score)

func on_player_died():
	print("Player morto - fermando il gioco")  # Debug
	stop_game()
	
	# Usa call_deferred per evitare problemi di timing
	call_deferred("_emit_player_died_signal")

func _emit_player_died_signal():
	print("Emettendo segnale player_died")  # Debug
	player_died.emit()

func reset_game():
	print("Resettando il gioco")  # Debug
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
