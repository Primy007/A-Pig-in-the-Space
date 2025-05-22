extends Node2D

class_name PowerUpSpawner

# Array delle scene di power-up disponibili
@export var powerup_scenes: Array[PackedScene] = []
# Tempo base tra spawn
@export var base_spawn_time: float = 10.0
# Variazione casuale del tempo di spawn
@export var spawn_time_variance: float = 5.0
# Distanza massima dal player per lo spawn
@export var spawn_distance: float = 1000.0
# Numero massimo di power-up contemporanei
@export var max_concurrent_powerups: int = 3

# Timer per lo spawn
@onready var spawn_timer: Timer = Timer.new()
# Array per tenere traccia dei power-up attivi
var active_powerups: Array = []
# Riferimento al player
var player: CharacterBody2D

func _ready():
	# Inizializza il timer
	add_child(spawn_timer)
	spawn_timer.wait_time = _get_random_spawn_time()
	spawn_timer.timeout.connect(_spawn_random_powerup)
	spawn_timer.start()
	
	# Trova il player
	player = get_tree().get_first_node_in_group("player")

func _get_random_spawn_time() -> float:
	return base_spawn_time + randf_range(-spawn_time_variance, spawn_time_variance)

func _spawn_random_powerup():
	# Non spawna se abbiamo raggiunto il limite massimo
	if active_powerups.size() >= max_concurrent_powerups:
		_reset_timer()
		return
	
	# Non spawna se non ci sono scene di power-up
	if powerup_scenes.is_empty():
		_reset_timer()
		return
		
	# Non spawna se il player non esiste
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if !is_instance_valid(player):
			_reset_timer()
			return
	
	# Sceglie una scena casuale
	var random_scene = powerup_scenes.pick_random()
	var powerup = random_scene.instantiate()
	
	# Trova una posizione casuale attorno al player
	var spawn_position = _get_random_spawn_position()
	powerup.global_position = spawn_position
	
	# Aggiunge il power-up alla scena
	get_tree().current_scene.add_child(powerup)
	active_powerups.append(powerup)
	
	# Connette il segnale per rimuoverlo dall'array quando viene distrutto
	powerup.tree_exited.connect(func(): _on_powerup_destroyed(powerup))
	
	# Reset del timer
	_reset_timer()

func _get_random_spawn_position() -> Vector2:
	# Calcola una posizione casuale in un cerchio attorno al player
	var angle = randf() * TAU  # Angolo casuale
	var distance = randf_range(spawn_distance * 0.3, spawn_distance)  # Distanza casuale
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player.global_position + offset

func _on_powerup_destroyed(powerup):
	# Rimuove il power-up dall'array quando viene distrutto
	if active_powerups.has(powerup):
		active_powerups.erase(powerup)

func _reset_timer():
	spawn_timer.wait_time = _get_random_spawn_time()
	spawn_timer.start()

# Funzione pubblica per forzare lo spawn di un power-up specifico
func force_spawn_powerup(powerup_scene: PackedScene, position: Vector2 = Vector2.ZERO):
	if !powerup_scene:
		return
		
	var powerup = powerup_scene.instantiate()
	
	if position == Vector2.ZERO:
		position = _get_random_spawn_position()
	
	powerup.global_position = position
	get_tree().current_scene.add_child(powerup)
	active_powerups.append(powerup)
	powerup.tree_exited.connect(func(): _on_powerup_destroyed(powerup))

# Funzione per pulire tutti i power-up attivi
func clear_all_powerups():
	for powerup in active_powerups:
		if is_instance_valid(powerup):
			powerup.queue_free()
	active_powerups.clear()
