# game_manager.gd
extends Node

# --- SINGLETON PATTERN ---
# Questo script dovrebbe essere un autoload (Singleton)

# --- SPAWN SETTINGS ---
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var min_spawn_distance: float = 1200.0  # Distanza minima dal player
@export var max_spawn_distance: float = 1800.0  # Distanza massima dal player
@export var spawn_margin: float = 200.0  # Margine dai bordi dello schermo

# --- SCORE SYSTEM ---
var current_score: int = 0
var points_per_enemy: int = 100

# --- REFERENCES ---
var spawn_timer: Timer
var player: CharacterBody2D
var score_label: Label

# --- SIGNALS ---
signal score_changed(new_score: int)
signal player_died

func _ready():
	_setup_spawn_timer()
	_connect_signals()

func _setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _connect_signals():
	score_changed.connect(_on_score_changed)

func start_game():
	current_score = 0
	score_changed.emit(current_score)
	player = get_tree().get_first_node_in_group("player")
	
	if spawn_timer:
		spawn_timer.start()

func stop_game():
	if spawn_timer:
		spawn_timer.stop()

func _spawn_enemy():
	if !is_instance_valid(player) or !enemy_scene:
		return
	
	var spawn_position = _get_random_spawn_position()
	if spawn_position == Vector2.ZERO:
		return  # Non è stata trovata una posizione valida
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	# Connetti il segnale di morte del nemico per aggiornare il punteggio
	if enemy.has_method("die"):
		# Modifica il metodo die del nemico per emettere un segnale
		enemy.tree_exited.connect(_on_enemy_died)
	
	get_tree().current_scene.add_child(enemy)

func _get_random_spawn_position() -> Vector2:
	if !player:
		return Vector2.ZERO
	
	var player_pos = player.global_position
	var attempts = 20  # Numero massimo di tentativi
	
	for i in attempts:
		# Genera un angolo casuale
		var angle = randf() * 2 * PI
		
		# Genera una distanza casuale tra min e max
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		
		# Calcola la posizione
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		
		# Verifica che la posizione sia valida (non troppo vicina ai bordi dello schermo)
		if _is_valid_spawn_position(spawn_pos):
			return spawn_pos
	
	# Se non trova una posizione valida, usa una posizione di fallback
	return player_pos + Vector2(min_spawn_distance, 0).rotated(randf() * 2 * PI)

func _is_valid_spawn_position(pos: Vector2) -> bool:
	var viewport = get_viewport().get_visible_rect()
	var camera = get_viewport().get_camera_2d()
	
	if !camera:
		return true  # Se non c'è camera, accetta la posizione
	
	# Calcola i bounds dello schermo considerando la posizione della camera
	var camera_pos = camera.global_position
	var screen_size = viewport.size / camera.zoom
	
	var left_bound = camera_pos.x - screen_size.x / 2 - spawn_margin
	var right_bound = camera_pos.x + screen_size.x / 2 + spawn_margin
	var top_bound = camera_pos.y - screen_size.y / 2 - spawn_margin
	var bottom_bound = camera_pos.y + screen_size.y / 2 + spawn_margin
	
	# La posizione è valida se è fuori dai bounds dello schermo
	return pos.x < left_bound or pos.x > right_bound or pos.y < top_bound or pos.y > bottom_bound

func _on_enemy_died():
	add_score(points_per_enemy)

func add_score(points: int):
	current_score += points
	score_changed.emit(current_score)

func get_current_score() -> int:
	return current_score

func _on_score_changed(new_score: int):
	# Aggiorna l'UI del punteggio se esiste
	if score_label:
		score_label.text = "Score: " + str(new_score)

func on_player_died():
	stop_game()
	player_died.emit()

# Funzione per resettare il gioco
func reset_game():
	current_score = 0
	score_changed.emit(current_score)
	
	# Rimuovi tutti i nemici esistenti
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

# Funzione per impostare il riferimento al score label dall'HUD
func set_score_label(label: Label):
	score_label = label
	if score_label:
		score_label.text = "Score: " + str(current_score)